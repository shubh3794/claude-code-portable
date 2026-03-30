# Claude Code Portable Config

Custom hooks and config that wire together ECC + GSD into a unified workflow.

## Architecture

```
ECC (everything-claude-code)  ← agents, skills, rules (--plugin-dir)
GSD (get-shit-done-cc)        ← workflow engine (npm package)
This repo                     ← custom hooks that engage both in tandem
```

## What's here

| Directory | What |
|-----------|------|
| `hooks/` | 10 custom hooks — workflow gates, context monitor, statusline, skill lifecycle |
| `rules/` | `ccg-skills.md`, `captain.md`, `mistake-discipline.md` |
| `agents/` | 15 agents (GSD + CCG) |
| `commands/` | 63 commands (GSD + CCG) |
| `skills/` | Domain skill packs |
| `CLAUDE.md.d/` | Global CLAUDE.md |

## Install on a new machine

```bash
# Clone this repo
git clone <this-repo> ~/claude-code-portable
cd ~/claude-code-portable
./install.sh
```

The script handles everything:
1. Clones ECC from GitHub → `~/everything-claude-code/`
2. Installs GSD via npm → `~/.claude/get-shit-done/`
3. Copies custom hooks/rules/agents/commands/skills → `~/.claude/`
4. Fixes hardcoded paths to match `$HOME`
5. Generates `settings.json` with correct hook paths

## Usage

```bash
claude --plugin-dir ~/everything-claude-code --dangerously-skip-permissions
```

Or alias it:
```bash
alias cc='claude --plugin-dir ~/everything-claude-code --dangerously-skip-permissions'
```
