#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"

echo "Installing Claude Code portable config..."
echo "  Source: $SCRIPT_DIR"
echo "  Target: $CLAUDE_DIR"
echo ""

# --- Safety: never clobber an existing setup without confirmation ---
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  read -p "~/.claude/settings.json already exists. Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborting. Existing setup untouched."
    exit 0
  fi
  # Back up the existing settings
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$(date +%s)"
  echo "  Backed up existing settings.json"
fi

mkdir -p "$CLAUDE_DIR"

# --- Copy portable directories ---
for dir in hooks rules agents commands get-shit-done skills; do
  if [ -d "$SCRIPT_DIR/$dir" ]; then
    echo "  Copying $dir/"
    mkdir -p "$CLAUDE_DIR/$dir"
    cp -R "$SCRIPT_DIR/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
  fi
done

# --- Copy CLAUDE.md ---
if [ -f "$SCRIPT_DIR/CLAUDE.md.d/CLAUDE.md" ]; then
  echo "  Copying CLAUDE.md"
  cp "$SCRIPT_DIR/CLAUDE.md.d/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# --- Fix ALL hardcoded home paths in copied files ---
# GSD files, ccg-skills.md, agents, etc. may contain /Users/<original-user>/.claude/
# Replace with the current user's path.
echo "  Fixing hardcoded paths → $CLAUDE_DIR/"
find "$CLAUDE_DIR/rules" "$CLAUDE_DIR/get-shit-done" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills" \
  -type f -name '*.md' 2>/dev/null | while read -r f; do
  if grep -q '/Users/[^/]*/.claude/' "$f" 2>/dev/null; then
    sed -i.bak "s|/Users/[^/]*/.claude/|$CLAUDE_DIR/|g" "$f"
    rm -f "${f}.bak"
  fi
done

# --- Generate settings.json with correct paths ---
echo "  Generating settings.json (hooks → $HOOKS_DIR)"

cat > "$CLAUDE_DIR/settings.json" << SETTINGS_EOF
{
  "model": "opus[1m]",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/gsd-check-update.js\""
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/skill-weekly-hygiene.js\"",
            "timeout": 5
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/skill-domain-bootstrap.js\"",
            "timeout": 5
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/project-rules-loader.js\"",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/gsd-context-monitor.js\""
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/gate-security-before-commit.js\"",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/gate-architect-after-plan.js\"",
            "timeout": 10
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/gate-code-review-after-execute.js\"",
            "timeout": 10
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "node \"$HOOKS_DIR/skill-capture-reminder.js\"",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "node \"$HOOKS_DIR/gsd-statusline.js\""
  },
  "enabledPlugins": {
    "gopls-lsp@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true
  },
  "skipDangerousModePermissionPrompt": true,
  "permissions": {
    "allow": [
      "Bash(*codeagent-wrapper*)"
    ]
  }
}
SETTINGS_EOF

# --- Fix any hardcoded home paths inside hooks that use os.homedir() ---
# The hooks already use os.homedir() so they're portable. Verify:
HARDCODED=$(grep -rl '/Users/shaggarw' "$HOOKS_DIR" 2>/dev/null || true)
if [ -n "$HARDCODED" ]; then
  echo ""
  echo "  WARNING: These hooks contain hardcoded paths (may need manual fix):"
  echo "$HARDCODED" | sed 's/^/    /'
fi

echo ""
echo "Done! Installed to $CLAUDE_DIR"
echo ""
echo "Next steps:"
echo "  1. Install plugins:  claude plugins install gopls-lsp@claude-plugins-official"
echo "  2. Verify:           claude --version && ls ~/.claude/settings.json"
