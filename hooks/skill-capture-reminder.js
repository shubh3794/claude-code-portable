#!/usr/bin/env node
// Stop hook: remind Claude to suggest /skill-from-chat after significant work
//
// Fires after each Claude response. Checks two signals:
// 1. GSD phase completion — .planning/STATE.md was modified this session
// 2. Significant code changes — git diff shows 50+ lines changed
//
// Uses a session-scoped flag file to avoid repeating the reminder.

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const tmpDir = os.tmpdir();

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;
    if (!sessionId) {
      process.exit(0);
    }

    // Only remind once per session
    const flagFile = path.join(tmpDir, `claude-skill-reminded-${sessionId}`);
    if (fs.existsSync(flagFile)) {
      process.exit(0);
    }

    const cwd = process.cwd();
    let shouldRemind = false;
    let reason = '';

    // Signal 1: GSD state file modified in last 30 minutes
    const stateFile = path.join(cwd, '.planning', 'STATE.md');
    if (fs.existsSync(stateFile)) {
      const mtime = fs.statSync(stateFile).mtime;
      const ageMinutes = (Date.now() - mtime.getTime()) / 60000;
      if (ageMinutes < 30) {
        shouldRemind = true;
        reason = 'GSD phase state was updated this session';
      }
    }

    // Signal 2: Significant code changes (50+ lines)
    if (!shouldRemind) {
      try {
        const diffStat = execSync('git diff --stat HEAD~1 2>/dev/null || git diff --stat 2>/dev/null', {
          encoding: 'utf8',
          timeout: 5000,
          cwd: cwd,
          windowsHide: true
        });
        const match = diffStat.match(/(\d+) insertions?/);
        if (match && parseInt(match[1]) >= 50) {
          shouldRemind = true;
          reason = `${match[1]} lines of insertions detected`;
        }
      } catch (e) {
        // git not available or no commits, skip
      }
    }

    if (!shouldRemind) {
      process.exit(0);
    }

    // Write flag so we don't remind again this session
    fs.writeFileSync(flagFile, Date.now().toString());

    const output = {
      systemMessage:
        `SKILL CAPTURE REMINDER: ${reason}. ` +
        'This session contained a multi-step workflow. ' +
        'Suggest to the user: "This session had significant work — want me to run /skill-from-chat to capture reusable patterns?"'
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
