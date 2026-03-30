---
name: skill-builder-agent
description: >
  Autonomous skill factory that monitors your Claude Code workflow patterns and generates
  contextual, job-specific skills on the fly. Use this skill whenever the user says things like
  "create a skill from what we just did", "turn this into a reusable workflow", "I keep doing this
  pattern", "automate this process", "build me a skill for X", "watch what I do and make it
  repeatable", "skill builder", "generate a skill", or when you notice the user repeating a
  multi-step workflow 2+ times. Also trigger when the user asks to "monitor my workflow",
  "learn from my patterns", "make this a command", or wants to capture tribal knowledge into
  a portable skill. This goes beyond the basic skill-creator by actively mining conversation
  history, CLAUDE.md lessons, git history, and shell history to propose skills proactively.
---

# Skill Builder Agent — Contextual Skill Factory

An autonomous agent that observes your development patterns and generates production-ready
Claude Code skills tuned to YOUR job, stack, and workflows. Unlike static skill imports,
these skills encode your team's tribal knowledge — the stuff that lives in your head and
your CLAUDE.md `## Lessons Learned` section.

## Philosophy

Most developers have 5-10 repeating workflows they execute manually every week:
- Debug cycle: repro → isolate → fix → test → PR
- Code review: checkout → read → annotate → suggest → comment
- Investigation: search logs → trace calls → read source → form hypothesis
- Onboarding: read docs → understand architecture → map dependencies

Each of these is a skill waiting to be born. This agent finds them and births them.

## How It Works

### Mode 1: Reactive — "Turn this into a skill"

When the user explicitly asks to capture a workflow:

1. **Mine the current conversation** for the sequence of actions taken
2. **Extract the pattern**: inputs → transformations → outputs → validation
3. **Identify variables** — what changes between invocations vs. what's constant
4. **Generate a SKILL.md** following the standard anatomy (see below)
5. **Create supporting scripts** if the workflow involves deterministic steps
6. **Write 2-3 eval test cases** based on the conversation that spawned it
7. **Package and present** the skill for installation

### Mode 2: Proactive — "Watch and suggest"

When running as a background observer (via custom command `/skill-watch`):

1. **Scan sources** for repeated patterns:
   - Shell history: `~/.bash_history` or `~/.zsh_history` (last 500 commands)
   - Git log: `git log --oneline -50` for commit message patterns
   - CLAUDE.md: `## Lessons Learned` section for recurring corrections
   - Recent conversations: look for repeated tool sequences

2. **Pattern detection heuristics**:
   - Same 3+ commands executed in sequence, 2+ times → candidate
   - Same file types created/modified in same order → candidate
   - CLAUDE.md correction that maps to a multi-step process → candidate
   - Git commits with similar prefixes (fix:, refactor:, test:) → candidate

3. **Propose skills** with a one-line summary + estimated value:
   ```
   Detected patterns:
   1. [HIGH] K8s pod debugging: kubectl describe → logs → events → restart
      → Could save ~15 min/occurrence, seen 4x this week
   2. [MED] CRIU checkpoint validation: build → deploy → trigger → verify
      → Complex 8-step process, seen 2x
   3. [LOW] PR template filling: branch → diff → format → push
      → Already partially automated, minor gains
   ```

4. **User picks** which to generate → agent builds the skill

### Mode 3: Domain-Specific Generation

For specialized domains, the agent reads domain context to generate richer skills:

**ML Infrastructure** (your domain):
- Read Kubernetes manifests, Volcano configs, GPU scheduling policies
- Generate skills for: job submission, checkpoint management, GPU utilization checks,
  failure diagnosis, capacity planning

**Distributed Systems**:
- Read service definitions, load balancer configs, tracing setups
- Generate skills for: latency investigation, failover testing, capacity modeling

**General Software**:
- Read CI/CD configs, test suites, deployment scripts
- Generate skills for: release workflows, hotfix procedures, dependency updates

## Skill Anatomy (What Gets Generated)

Every generated skill follows this structure:

```
generated-skill-name/
├── SKILL.md              # Instructions + when to trigger
├── scripts/              # Deterministic automation
│   ├── run.sh           # Main executable (if applicable)
│   └── validate.sh      # Post-execution checks
├── references/           # Domain docs loaded on demand
│   └── context.md       # Relevant architecture/API docs
└── templates/            # Output templates
    └── output.md        # Standard output format
```

### SKILL.md Template

```markdown
---
name: <skill-name>
description: >
  <What it does. When to trigger — be pushy with trigger phrases.
  Include both explicit triggers ("run X workflow") and implicit ones
  ("I need to debug this pod", "why is this job failing").>
---

# <Skill Name>

## Context
<Why this skill exists. What problem it solves. What domain knowledge it encodes.>

## Prerequisites
<Tools, access, environment needed>

## Workflow

### Step 1: <Gather Context>
<What to read/check first. Reference files to consult.>

### Step 2: <Execute>
<The core actions. Scripts to run. Commands to execute.>

### Step 3: <Validate>
<How to verify success. What to check. Expected outputs.>

### Step 4: <Report>
<Output format. What to tell the user. Next steps.>

## Edge Cases
<What can go wrong. How to handle failures. Fallback paths.>

## Examples
<1-2 concrete examples of input → output>
```

## Generating a Skill: Step-by-Step

When generating a skill (any mode), follow this sequence:

### 1. Gather Raw Material

```bash
# Shell history patterns
grep -E "kubectl|docker|git|python|npm" ~/.zsh_history | tail -200

# Git commit patterns
git log --oneline --since="2 weeks ago" | head -30

# CLAUDE.md lessons
cat CLAUDE.md | grep -A5 "Lesson\|learned\|mistake\|always\|never"
```

### 2. Interview the User (if reactive mode)

Ask these questions (skip what's obvious from context):
- "What triggers this workflow? What's the starting condition?"
- "What varies each time vs. what's always the same?"
- "What's the definition of done? How do you know it worked?"
- "Any gotchas or edge cases you've hit?"

### 3. Draft the Skill

Write the SKILL.md with:
- **Aggressive trigger description** — err on the side of triggering too often
- **Step-by-step workflow** — imperative instructions, not explanations
- **Concrete examples** — use real data shapes from the user's domain
- **Escape hatches** — what to do when the happy path fails

### 4. Generate Supporting Scripts

If the workflow has deterministic steps (API calls, file transforms, command sequences),
extract them into scripts:

```bash
#!/bin/bash
# scripts/run.sh — Generated by skill-builder-agent
# Purpose: <one-line description>
# Usage: ./run.sh <args>
set -euo pipefail

# Step 1: ...
# Step 2: ...
```

### 5. Write Test Cases

Create `evals/evals.json` with 2-3 realistic prompts:

```json
{
  "skill_name": "<name>",
  "evals": [
    {
      "id": 1,
      "prompt": "<realistic user prompt that should trigger this skill>",
      "expected_output": "<what success looks like>"
    }
  ]
}
```

### 6. Package the Skill

Place the completed skill directory where Claude Code can find it.
For Claude Code CLI: copy to `~/.claude/skills/` or the project's `.claude/skills/`.

Inform the user:
- Where the skill was saved
- How to trigger it (exact phrases)
- How to iterate on it (edit SKILL.md, update lessons)

## Custom Commands to Install

The skill-builder-agent comes with custom commands the user should add to their
`.claude/commands/` directory:

### `/skill-watch` — Proactive Pattern Scanner
Scans recent history and proposes skills. Run periodically (e.g., end of week).

### `/skill-from-chat` — Capture Current Conversation
Analyzes the current conversation and extracts a reusable skill from it.

### `/skill-for <domain>` — Domain-Specific Generator
Generates a skill tailored to a specific domain by reading project configs.

## Important Notes

- Generated skills should be treated as drafts — the user should review and iterate
- Keep SKILL.md under 500 lines; use references/ for bulky domain docs
- Trigger descriptions should be "pushy" — better to over-trigger than under-trigger
- Scripts must be idempotent and safe to re-run
- Never hardcode secrets, tokens, or environment-specific paths in skills
- Include the source pattern (conversation, git history, etc.) in a comment at the top
  of generated SKILL.md files so the user knows where it came from
