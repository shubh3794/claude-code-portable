#!/usr/bin/env node
// PreToolUse hook on Bash: inject security review reminder before git commit
//
// Detection: Bash command contains "git commit"
// Injects additionalContext telling Claude to run security-reviewer first.
// Uses a session flag so the reminder fires once — after the review passes,
// subsequent commits in the same session proceed without re-triggering.

const fs = require('fs');
const path = require('path');
const os = require('os');

const tmpDir = os.tmpdir();

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;
    const command = data.tool_input?.command || '';

    if (!sessionId) {
      console.log(input);
      process.exit(0);
    }

    // Only trigger on git commit commands
    if (!/git\s+commit/.test(command)) {
      console.log(input);
      process.exit(0);
    }

    // Check if security review already completed this session
    const flagFile = path.join(tmpDir, `claude-security-gate-${sessionId}`);
    if (fs.existsSync(flagFile)) {
      console.log(input);
      process.exit(0);
    }

    // Write flag — after security review, Claude should touch this flag
    // by running a commit again (this hook won't fire twice)
    fs.writeFileSync(flagFile, Date.now().toString());

    // Warn (stderr) — does not block the commit, but Claude sees the message
    console.error(
      'WORKFLOW GATE — SECURITY REVIEW REQUIRED: You are about to commit. ' +
      'Per mandatory workflow gates, spawn the **security-reviewer** agent to scan for ' +
      'hardcoded secrets, injection vulnerabilities, and OWASP Top 10 issues on all staged files ' +
      'BEFORE committing. If the review has already been done this session, proceed with the commit.'
    );

    // Pass through input unchanged
    console.log(input);
    process.exit(0);
  } catch (e) {
    // Pass through on error — never block
    if (input) console.log(input);
    process.exit(0);
  }
});
