#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"

echo "=== Claude Code Portable Installer ==="
echo ""
echo "  Source: $SCRIPT_DIR"
echo "  Target: $CLAUDE_DIR"
echo ""

# -------------------------------------------------------
# Step 1: Install ECC (everything-claude-code) if missing
# -------------------------------------------------------
if [ ! -f "$CLAUDE_DIR/ecc/install-state.json" ]; then
  echo "[1/4] ECC not found. Installing everything-claude-code..."
  if command -v claude &>/dev/null; then
    echo "  Run:  claude plugins install everything-claude-code"
    echo "  Then re-run this script."
  else
    echo "  Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
  fi
  exit 1
else
  echo "[1/4] ECC already installed. Skipping."
fi

# -------------------------------------------------------
# Step 2: Back up existing settings.json
# -------------------------------------------------------
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  BACKUP="$CLAUDE_DIR/settings.json.bak.$(date +%s)"
  cp "$CLAUDE_DIR/settings.json" "$BACKUP"
  echo "[2/4] Backed up settings.json → $(basename "$BACKUP")"
else
  echo "[2/4] No existing settings.json. Fresh install."
fi

# -------------------------------------------------------
# Step 3: Copy custom files (overlay on top of ECC)
# -------------------------------------------------------
echo "[3/4] Copying custom files..."

for dir in hooks rules agents commands get-shit-done skills; do
  if [ -d "$SCRIPT_DIR/$dir" ]; then
    # Use rsync to merge without deleting ECC files
    if command -v rsync &>/dev/null; then
      rsync -a "$SCRIPT_DIR/$dir/" "$CLAUDE_DIR/$dir/"
    else
      cp -R "$SCRIPT_DIR/$dir/"* "$CLAUDE_DIR/$dir/" 2>/dev/null || true
    fi
    count=$(find "$SCRIPT_DIR/$dir" -type f | wc -l | tr -d ' ')
    echo "  $dir/ ($count files)"
  fi
done

if [ -f "$SCRIPT_DIR/CLAUDE.md.d/CLAUDE.md" ]; then
  cp "$SCRIPT_DIR/CLAUDE.md.d/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "  CLAUDE.md"
fi

# -------------------------------------------------------
# Step 3b: Fix hardcoded home paths in all .md files
# -------------------------------------------------------
echo "  Fixing hardcoded paths..."
find "$CLAUDE_DIR/get-shit-done" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/rules" \
  -type f -name '*.md' 2>/dev/null | while read -r f; do
  if grep -q '/Users/[^/]*/.claude/' "$f" 2>/dev/null; then
    if [[ "$OSTYPE" == darwin* ]]; then
      sed -i '' "s|/Users/[^/]*/.claude/|$CLAUDE_DIR/|g" "$f"
    else
      sed -i "s|/Users/[^/]*/.claude/|$CLAUDE_DIR/|g" "$f"
    fi
  fi
done

# -------------------------------------------------------
# Step 4: Generate settings.json with resolved paths
# -------------------------------------------------------
echo "[4/4] Generating settings.json..."

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

echo ""
echo "Done! Your setup is live at $CLAUDE_DIR"
echo ""
echo "Verify: claude --version"
