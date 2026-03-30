## Mandatory Workflow Gates (Global)

See [rules/common/agents.md](rules/common/agents.md) — single source of truth for all workflow gates.
Gates are enforced by hooks in `~/.claude/hooks/gate-*.js`.

## Skill Builder Auto-Loop

### Capture (after every session)
- After completing any GSD session or multi-step workflow → run `/skill-from-chat`
- For project-specific skills: install to `.claude/skills/` in the current project, not globally
- For reusable cross-project skills: install globally to `~/.claude/skills/`

### Evolve (continuous)
- After completing any multi-step workflow 2+ times → suggest running `/skill-from-chat`
- After any `/gsd:verify` → check if the verification pattern should become a skill
- When a skill fires but gives wrong guidance → update the skill's Edge Cases section

### Weekly Hygiene (Friday afternoon)
- Run `/skill-watch` to scan shell history, git log, and CLAUDE.md for uncaptured patterns

### New Domain Bootstrap
- When starting work in a new area → run `/skill-for <domain>` to generate domain-specific skills upfront
- Examples: `/skill-for volcano-preemption`, `/skill-for criu-cuda-checkpoint`, `/skill-for gpu-scheduling-debug`

### Compounding Loop
```
Week 1: /gsd:execute → finish task → /skill-from-chat → skill created
Week 2: Same task type → skill auto-activates → faster execution
Week 3: /skill-watch finds missed patterns → more skills
Week 4: Claude Code deeply tuned to your stack
```
GSD = workflow discipline. ECC = specialist agents. Skill-builder = compounding over time.
