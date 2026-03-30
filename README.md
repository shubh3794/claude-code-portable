# Claude Code Portable Config

Portable Claude Code setup. Works on any machine — no hardcoded paths.

## What's included

| Directory | Contents |
|-----------|----------|
| `hooks/` | Workflow gates, context monitor, statusline, skill reminders |
| `rules/` | Common coding standards, CCG quality gates |
| `agents/` | Specialist agents (GSD, reviewers, builders) |
| `skills/` | Domain skill packs |
| `commands/` | CLI command definitions |
| `get-shit-done/` | GSD workflow engine |
| `CLAUDE.md.d/` | Global CLAUDE.md |

## What's NOT included

- LinkedIn plugins (work-specific, reinstall separately)
- Memory/projects (machine-specific, builds up over time)
- Sessions/cache (ephemeral)

## Install

```bash
git clone <this-repo> ~/claude-code-portable
cd ~/claude-code-portable
./install.sh
```

The install script:
1. Copies all files into `~/.claude/`
2. Generates `settings.json` with paths resolved to your `$HOME`
3. Fixes any hardcoded paths in GSD/agent/skill markdown files
4. Backs up existing `settings.json` if present

## Post-install

```bash
# Install non-work plugins
claude plugins install gopls-lsp@claude-plugins-official
claude plugins install claude-code-setup@claude-plugins-official
```
