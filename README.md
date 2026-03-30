# Claude Code Portable Config

Custom overlay on top of [everything-claude-code (ECC)](https://github.com/affaan-m/everything-claude-code).

## Architecture

```
ECC (421 files)          ← base: agents, rules, skills, hooks framework
  + this repo (1,604 files) ← overlay: custom hooks, GSD, CCG, domain skills
  = full setup
```

## What's in this repo (YOUR stuff only)

| Directory | Files | What |
|-----------|-------|------|
| `hooks/` | 10 | Workflow gates, context monitor, statusline, skill reminders, project-rules-loader |
| `rules/` | 3 | `captain.md`, `ccg-skills.md`, `mistake-discipline.md` |
| `agents/` | 15 | GSD agents, CCG agents |
| `commands/` | 63 | CCG commands, GSD commands |
| `skills/` | 1,414 | Domain skill packs |
| `get-shit-done/` | 95 | GSD workflow engine |
| `CLAUDE.md` | 1 | Global instructions |

## What's NOT in this repo

- ECC base (reinstall from source)
- LinkedIn plugins (work-only)
- Memory/projects (machine-specific, builds over time)
- Sessions/cache (ephemeral)

## Install on a new machine

```bash
# 1. Install Claude Code
# https://docs.anthropic.com/en/docs/claude-code

# 2. Install ECC
claude plugins install everything-claude-code

# 3. Clone and overlay your customizations
git clone <this-repo> ~/claude-code-portable
cd ~/claude-code-portable
./install.sh
```

The install script:
1. Verifies ECC is installed
2. Backs up existing `settings.json`
3. Merges your files on top of ECC (doesn't delete ECC files)
4. Fixes hardcoded `/Users/<anyone>/.claude/` paths to match `$HOME`
5. Generates `settings.json` with correct hook paths
