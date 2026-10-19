# claude-code-portable

A small Claude Code plugin: skill-capture reminders, skill-creation commands, and a few language skills.
Designed to run alongside [Superpowers](https://github.com/obra/superpowers), which provides the
plan → execute → review workflow.

## Install

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

/plugin install portable --marketplace shubh3794/claude-code-portable
```

Product skills (discovery, user research, strategy) are a separate plugin — install them per project:

```
/plugin install product --marketplace shubh3794/claude-code-portable --scope project
```

Optional statusline (model │ dir │ context used %), in `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "node ~/claude-code-portable/statusline.js" }
```

## What's in it

| | |
|---|---|
| `hooks/` | Reminders shown to **you** (zero tokens — Claude never sees them): capture a skill after significant work, `/skill-watch` on Fridays, bootstrap domain skills listed in a project's CLAUDE.md |
| `commands/` | `/skill-from-chat`, `/skill-for <domain>`, `/skill-watch` |
| `skills/` | `go`, `python`, `cuda`, `java`, `docker-patterns`, `postgres-patterns`, `skill-builder-agent` |
| `statusline.js` | Context usage at a glance |
| `plugins/product/` | Separate plugin: 32 product discovery / user research / strategy skills + 13 commands, from [phuryn/pm-skills](https://github.com/phuryn/pm-skills) (MIT) |

## Where skills go

- **Cross-project** (languages, tools you use everywhere) → `skills/` in this repo.
- **Project/domain-specific** → that project's `.claude/skills/`. Keeps unrelated descriptions out of every session.

Keep each skill's `description` to 1–3 lines — every description is loaded into every session.
Check the fixed cost with `/context` in a fresh session.
