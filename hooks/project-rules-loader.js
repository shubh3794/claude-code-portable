#!/usr/bin/env node
// SessionStart hook: detect project type and tell Claude to load language-specific rules.
//
// Detection logic:
//   Python/ML: *.py files + (requirements.txt OR setup.py OR pyproject.toml OR setup.cfg)
//   TypeScript: package.json + tsconfig.json
//   Go: go.mod
//   Rust: Cargo.toml
//   Java/Kotlin: build.gradle + src/main/java (without Python markers → pure JVM)
//
// When detected, injects additionalContext telling Claude to Read the overlay files.
// The overlay files are NOT auto-loaded into context — Claude reads them on demand,
// saving context when they're not needed for the current task.

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const rulesDir = path.join(homeDir, '.claude', 'lang-rules');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const cwd = process.cwd();
    const detected = [];

    // Python / ML detection
    const pyMarkers = ['requirements.txt', 'setup.py', 'pyproject.toml', 'setup.cfg'];
    const hasPyMarker = pyMarkers.some(f => fs.existsSync(path.join(cwd, f)));
    // Also check one level deep (monorepo subdirs)
    let hasPySubdir = false;
    if (!hasPyMarker) {
      try {
        const entries = fs.readdirSync(cwd, { withFileTypes: true });
        for (const e of entries) {
          if (e.isDirectory()) {
            if (pyMarkers.some(f => fs.existsSync(path.join(cwd, e.name, f)))) {
              hasPySubdir = true;
              break;
            }
          }
        }
      } catch (e) {}
    }
    if (hasPyMarker || hasPySubdir) {
      const pyRulesDir = path.join(rulesDir, 'python');
      if (fs.existsSync(pyRulesDir)) {
        detected.push({
          language: 'Python/ML',
          rulesDir: pyRulesDir,
          files: fs.readdirSync(pyRulesDir).filter(f => f.endsWith('.md'))
        });
      }
    }

    // TypeScript detection
    if (fs.existsSync(path.join(cwd, 'package.json')) && fs.existsSync(path.join(cwd, 'tsconfig.json'))) {
      const tsRulesDir = path.join(rulesDir, 'typescript');
      if (fs.existsSync(tsRulesDir)) {
        detected.push({
          language: 'TypeScript',
          rulesDir: tsRulesDir,
          files: fs.readdirSync(tsRulesDir).filter(f => f.endsWith('.md'))
        });
      }
    }

    // Go detection
    if (fs.existsSync(path.join(cwd, 'go.mod'))) {
      const goRulesDir = path.join(rulesDir, 'golang');
      if (fs.existsSync(goRulesDir)) {
        detected.push({
          language: 'Go',
          rulesDir: goRulesDir,
          files: fs.readdirSync(goRulesDir).filter(f => f.endsWith('.md'))
        });
      }
    }

    // Rust detection
    if (fs.existsSync(path.join(cwd, 'Cargo.toml'))) {
      const rustRulesDir = path.join(rulesDir, 'rust');
      if (fs.existsSync(rustRulesDir)) {
        detected.push({
          language: 'Rust',
          rulesDir: rustRulesDir,
          files: fs.readdirSync(rustRulesDir).filter(f => f.endsWith('.md'))
        });
      }
    }

    // Java detection (build.gradle or pom.xml, with src/main/java or .java files)
    const hasGradle = fs.existsSync(path.join(cwd, 'build.gradle')) || fs.existsSync(path.join(cwd, 'build.gradle.kts'));
    const hasMaven = fs.existsSync(path.join(cwd, 'pom.xml'));
    if (hasGradle || hasMaven) {
      const javaRulesDir = path.join(rulesDir, 'java');
      if (fs.existsSync(javaRulesDir)) {
        detected.push({
          language: 'Java',
          rulesDir: javaRulesDir,
          files: fs.readdirSync(javaRulesDir).filter(f => f.endsWith('.md'))
        });
      }
    }

    if (detected.length === 0) {
      process.exit(0);
    }

    // Build the instruction for Claude
    const instructions = detected.map(d => {
      const filePaths = d.files.map(f => path.join(d.rulesDir, f));
      return `${d.language} project detected. Read these rule overrides before writing code:\n` +
        filePaths.map(p => `  - ${p}`).join('\n');
    }).join('\n\n');

    const output = {
      systemMessage:
        `PROJECT RULES: ${instructions}\n\n` +
        'These override the common rules in ~/.claude/rules/common/ for this project. ' +
        'Language-specific rules take precedence over common rules when they conflict.'
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
