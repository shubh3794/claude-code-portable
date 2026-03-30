# Mistake Discipline

## Recognize and Break Failing Patterns

### Rule: Two strikes, then stop and think

If the same operation fails twice, you are in a retry loop. STOP executing and switch to understanding:
1. Read the FULL error, not just the last line
2. Diff against the last known-good invocation
3. Verify ALL preconditions (env, permissions, state, deps)
4. Only then construct the next attempt

### Rule: Environment is never inherited

When executing in a different context (nsenter, ssh, docker exec, kubectl exec, subprocess, CI runner), NEVER assume the target has the same PATH, env vars, or tools. Always set them explicitly.

### Rule: Side-effect-free before side-effect-ful

Before any state-changing command, run the read-only diagnostic version first. Validate preconditions without risking corruption.

Examples:
- Before destructive writes → read current state
- Before deploys → dry-run or diff
- Before process-level operations → check process state, verify tools exist
- Before git force operations → check what will be overwritten

### Rule: Get it right the first time for irreversible operations

When an operation has side effects that are hard to undo (process state, GPU state, database mutations, deploys, destructive git ops):
- Review all required flags/options from docs or prior runs BEFORE composing the command
- Compare against the last known-good invocation
- Never "try and see" — construct the correct command, then execute once

### Rule: Route skill-related corrections to the skill

When a user corrects behavior that originated from a skill (e.g., "that's wrong", "don't do that", "no" after a skill fired), update that skill's **Edge Cases** section with what went wrong and the correct behavior BEFORE proceeding with the fix. This ensures the skill self-corrects for future sessions, not just the current one. If no Edge Cases section exists, create one.

### Rule: Log mistakes immediately

When a mistake is identified (by user correction or repeated failure), log it as a feedback memory BEFORE proceeding with the fix. Include:
- What went wrong (symptom)
- Why (root cause)
- How to prevent it (the rule)

The user should never have to correct the same mistake twice.

### Rule: When something worked before, diff against it

Don't guess why a previously working operation fails. Find the exact prior command and compare character-by-character. The difference IS the bug.

### Rule: Log successful executions as reference

When a complex or multi-flag command succeeds, immediately save the exact command, context, and result as a memory or comment. This creates a known-good baseline to diff against when things break later.

What to log:
- The exact command that worked (copy-paste, no paraphrasing)
- Key environment details (node, container, versions, state)
- Output summary (timing, sizes, exit codes)
- Any non-obvious preconditions that made it work

**Why:** Success is as informative as failure. Without a logged baseline, you have nothing to diff against when the next attempt fails. Most debugging is "what changed since it last worked?" — if you didn't record what worked, you're guessing.

**How to apply:** After any non-trivial operation succeeds (deploy, build, checkpoint, migration, CI pass), save the working command and context to a memory file or inline comment before moving on. Treat successful runs as reference data, not disposable output.
