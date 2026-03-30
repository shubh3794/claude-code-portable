#!/usr/bin/env node
// Stop hook: inject architect agent reminder after GSD plan/research phase
//
// Detection signals:
// 1. A PLAN.md or RESEARCH.md in .planning/phases/ was modified in last 10 minutes
// 2. Not already reminded this session for the same file
//
// Injects additionalContext telling Claude to spawn the architect agent.

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
    const phasesDir = path.join(cwd, '.planning', 'phases');
    if (!fs.existsSync(phasesDir)) { process.exit(0); }

    // Find recently modified PLAN.md or RESEARCH.md files
    let recentFile = null;
    try {
      const result = execSync(
        `find "${phasesDir}" -maxdepth 3 \\( -name "*-PLAN.md" -o -name "*-RESEARCH.md" \\) -mmin -${RECENCY_MINUTES} 2>/dev/null`,
        { encoding: 'utf8', timeout: 5000, windowsHide: true }
      ).trim();
      if (result) {
        recentFile = result.split('\n')[0];
      }
    } catch (e) { process.exit(0); }

    if (!recentFile) { process.exit(0); }

    // Deduplicate: track which files we've already reminded about
    const flagFile = path.join(tmpDir, `claude-architect-gate-${sessionId}.json`);
    let reminded = {};
    if (fs.existsSync(flagFile)) {
      try { reminded = JSON.parse(fs.readFileSync(flagFile, 'utf8')); } catch (e) {}
    }

    const fileKey = path.basename(recentFile);
    if (reminded[fileKey]) { process.exit(0); }

    reminded[fileKey] = Date.now();
    fs.writeFileSync(flagFile, JSON.stringify(reminded));

    const output = {
      systemMessage:
        `WORKFLOW GATE — ARCHITECT REVIEW REQUIRED: "${fileKey}" was just created/updated. ` +
        'Per mandatory workflow gates, you MUST now spawn the **architect** agent to evaluate this plan/research output ' +
        'for architectural soundness, scalability, and trade-offs BEFORE proceeding to implementation.'
    };

    process.stdout.write(JSON.stringify(output));
  } catch (e) { process.exit(0); }
});
