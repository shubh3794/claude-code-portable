#!/usr/bin/env node
// SessionStart hook: remind to bootstrap domain skills if project lists them but none exist
//
// Detection:
// 1. Project CLAUDE.md lists domain skills (contains "/skill-for")
// 2. Project .claude/skills/ is empty or missing SKILL.md files
//
// Fires once per project per week (flag file tracks last reminder).

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const cacheDir = path.join(homeDir, '.claude', 'cache');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const cwd = process.cwd();

    // Check project CLAUDE.md for /skill-for references
    const claudeMd = path.join(cwd, 'CLAUDE.md');
    if (!fs.existsSync(claudeMd)) { process.exit(0); }

    const content = fs.readFileSync(claudeMd, 'utf8');
    if (!/\/skill-for/.test(content)) { process.exit(0); }

    // Extract domain names from backtick-quoted skill-for targets
    const domains = [];
    const lines = content.split('\n');
    for (const line of lines) {
      const match = line.match(/`([^`]+)`\s*[—\-]/);
      if (match && !line.includes('run `/skill-for')) {
        domains.push(match[1]);
      }
    }

    if (domains.length === 0) { process.exit(0); }

    // Check if .claude/skills/ has any SKILL.md files
    const skillsDir = path.join(cwd, '.claude', 'skills');
    let hasSkills = false;
    if (fs.existsSync(skillsDir)) {
      try {
        const files = fs.readdirSync(skillsDir, { recursive: true });
        hasSkills = files.some(f => f.toString().endsWith('SKILL.md'));
      } catch (e) {}
    }

    if (hasSkills) { process.exit(0); }

    // Deduplicate: once per project per week
    if (!fs.existsSync(cacheDir)) {
      fs.mkdirSync(cacheDir, { recursive: true });
    }
    const projectKey = cwd.replace(/\//g, '_');
    const flagFile = path.join(cacheDir, `skill-bootstrap-${projectKey}.json`);

    if (fs.existsSync(flagFile)) {
      try {
        const data = JSON.parse(fs.readFileSync(flagFile, 'utf8'));
        const daysSince = (Date.now() - new Date(data.timestamp).getTime()) / (1000 * 60 * 60 * 24);
        if (daysSince < 7) { process.exit(0); }
      } catch (e) {}
    }

    fs.writeFileSync(flagFile, JSON.stringify({ timestamp: new Date().toISOString() }));

    const domainList = domains.map(d => `/skill-for ${d}`).join(', ');
    const output = {
      systemMessage:
        `SKILL BOOTSTRAP REMINDER: This project lists ${domains.length} domain skills to generate ` +
        `but .claude/skills/ has no SKILL.md files yet. Suggest to the user: ` +
        `"Want me to bootstrap domain skills? I can run: ${domainList}"`
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
