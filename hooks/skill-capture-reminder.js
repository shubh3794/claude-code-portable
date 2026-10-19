#!/usr/bin/env node
// Stop hook: remind the user to run /skill-from-chat after significant work
//
// Fires after each Claude response. Signal: 50+ lines inserted across
// uncommitted changes plus commits from the last 2 hours.
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

    const cwd = data.cwd || process.cwd();
    let shouldRemind = false;
    let reason = '';

    try {
      const opts = { encoding: 'utf8', timeout: 5000, cwd, windowsHide: true };
      const sumInsertions = out => [...out.matchAll(/(\d+) insertions?/g)]
        .reduce((n, m) => n + parseInt(m[1]), 0);
      const lines =
        sumInsertions(execSync('git diff --shortstat HEAD 2>/dev/null || true', opts)) +
        sumInsertions(execSync('git log --since="2 hours ago" --shortstat --format= 2>/dev/null || true', opts));
      if (lines >= 50) {
        shouldRemind = true;
        reason = `${lines} lines added recently`;
      }
    } catch (e) {
      // git not available, skip
    }

    if (!shouldRemind) {
      process.exit(0);
    }

    // Write flag so we don't remind again this session
    fs.writeFileSync(flagFile, Date.now().toString());

    const output = {
      systemMessage:
        `Skill capture: ${reason}. Run /skill-from-chat to turn this workflow into a reusable skill.`
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
