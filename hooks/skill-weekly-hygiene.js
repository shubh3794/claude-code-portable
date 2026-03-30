#!/usr/bin/env node
// SessionStart hook: remind to run /skill-watch on Fridays
//
// Detection: today is Friday AND /skill-watch hasn't run this week.
// Uses a weekly flag file in ~/.claude/cache/ to track last run.

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const cacheDir = path.join(homeDir, '.claude', 'cache');
const flagFile = path.join(cacheDir, 'skill-watch-last-run.json');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const now = new Date();
    const dayOfWeek = now.getDay(); // 0=Sun, 5=Fri

    // Only fire on Friday (5)
    if (dayOfWeek !== 5) {
      process.exit(0);
    }

    // Check if already run this week
    if (fs.existsSync(flagFile)) {
      try {
        const data = JSON.parse(fs.readFileSync(flagFile, 'utf8'));
        const lastRun = new Date(data.timestamp);
        const daysSince = (now - lastRun) / (1000 * 60 * 60 * 24);
        if (daysSince < 6) {
          // Already ran this week
          process.exit(0);
        }
      } catch (e) {}
    }

    // Ensure cache dir exists
    if (!fs.existsSync(cacheDir)) {
      fs.mkdirSync(cacheDir, { recursive: true });
    }

    // Write flag so we don't remind again this week
    fs.writeFileSync(flagFile, JSON.stringify({ timestamp: now.toISOString() }));

    const output = {
      systemMessage:
        'SKILL HYGIENE REMINDER: It\'s Friday. Run `/skill-watch` to scan shell history, ' +
        'git log, and CLAUDE.md for patterns that haven\'t been captured as skills yet. ' +
        'Suggest this to the user at a natural pause point.'
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    process.exit(0);
  }
});
