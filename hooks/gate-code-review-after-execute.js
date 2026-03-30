#!/usr/bin/env node
// Stop hook: inject code-reviewer agent reminder after GSD execute phase
//
// Detection signals:
// 1. A SUMMARY.md in .planning/phases/ was modified in last 10 minutes
//    (GSD executor writes SUMMARY.md on phase completion)
// 2. OR git diff shows 30+ lines of staged/unstaged changes
//    AND .planning/STATE.md indicates execution phase
//
// Fires once per detected completion per session.

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const tmpDir = os.tmpdir();
const RECENCY_MINUTES = 10;

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;
    if (!sessionId) { process.exit(0); }

    const cwd = process.cwd();
    let shouldRemind = false;
    let reason = '';

    // Signal 1: SUMMARY.md recently modified (GSD phase completion marker)
    const phasesDir = path.join(cwd, '.planning', 'phases');
    if (fs.existsSync(phasesDir)) {
      try {
        const result = execSync(
          `find "${phasesDir}" -maxdepth 3 -name "*-SUMMARY.md" -mmin -${RECENCY_MINUTES} 2>/dev/null`,
          { encoding: 'utf8', timeout: 5000, windowsHide: true }
        ).trim();
        if (result) {
          shouldRemind = true;
          reason = `GSD phase completed: ${path.basename(result.split('\n')[0])}`;
        }
      } catch (e) {}
    }

    // Signal 2: Significant code changes (not just planning files)
    if (!shouldRemind) {
      try {
        const diff = execSync('git diff --stat 2>/dev/null', {
          encoding: 'utf8', timeout: 5000, cwd, windowsHide: true
        });
        const match = diff.match(/(\d+) insertions?/);
        const lines = match ? parseInt(match[1]) : 0;
        // Check that STATE.md mentions execution
        const stateFile = path.join(cwd, '.planning', 'STATE.md');
        let inExecution = false;
        if (fs.existsSync(stateFile)) {
          const state = fs.readFileSync(stateFile, 'utf8');
          inExecution = /execut/i.test(state) || /implement/i.test(state);
        }
        if (lines >= 30 && inExecution) {
          shouldRemind = true;
          reason = `${lines} lines changed during execution phase`;
        }
      } catch (e) {}
    }

    if (!shouldRemind) { process.exit(0); }

    // Deduplicate per session
    const flagFile = path.join(tmpDir, `claude-codereview-gate-${sessionId}.json`);
    let reminded = {};
    if (fs.existsSync(flagFile)) {
      try { reminded = JSON.parse(fs.readFileSync(flagFile, 'utf8')); } catch (e) {}
    }

    if (reminded[reason]) { process.exit(0); }
    reminded[reason] = Date.now();
    fs.writeFileSync(flagFile, JSON.stringify(reminded));

    const output = {
      systemMessage:
        `WORKFLOW GATE — CODE REVIEW REQUIRED: ${reason}. ` +
        'Per mandatory workflow gates, you MUST now spawn the **code-reviewer** agent to review all changed files ' +
        'for quality, security, and maintainability BEFORE proceeding to commit.'
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) { process.exit(0); }
});
