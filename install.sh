#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
ECC_DIR="$HOME/everything-claude-code"

echo "=== Claude Code Portable Installer ==="
echo ""

# -------------------------------------------------------
# Step 1: Install GSD (get-shit-done-cc)
# -------------------------------------------------------
echo "[1/4] Installing get-shit-done-cc..."
npm install -g get-shit-done-cc

# -------------------------------------------------------
# Step 2: Clone ECC if not present
# -------------------------------------------------------
if [ -d "$ECC_DIR/.git" ]; then
  echo "[2/4] ECC already at $ECC_DIR"
else
  echo "[2/4] Cloning everything-claude-code..."
  git clone https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR"
fi

# -------------------------------------------------------
# Step 2: Copy custom files into ~/.claude/
# -------------------------------------------------------
echo "[3/4] Copying custom files..."

mkdir -p "$CLAUDE_DIR"

for dir in hooks rules agents commands skills; do
  if [ -d "$SCRIPT_DIR/$dir" ]; then
    mkdir -p "$CLAUDE_DIR/$dir"
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

# Fix hardcoded home paths
echo "  Fixing hardcoded paths..."
for search_dir in "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/rules"; do
  [ -d "$search_dir" ] || continue
  find "$search_dir" -type f -name '*.md' 2>/dev/null | while read -r f; do
    if grep -q '/Users/[^/]*/.claude/' "$f" 2>/dev/null; then
      if [[ "$OSTYPE" == darwin* ]]; then
        sed -i '' "s|/Users/[^/]*/.claude/|$CLAUDE_DIR/|g" "$f"
      else
        sed -i "s|/Users/[^/]*/.claude/|$CLAUDE_DIR/|g" "$f"
      fi
    fi
  done
done

# -------------------------------------------------------
# Step 3: Generate settings.json
# -------------------------------------------------------
echo "[4/4] Generating settings.json..."

if [ -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak.$(date +%s)"
fi

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
echo "Done! Run:"
echo "  claude --plugin-dir $ECC_DIR --dangerously-skip-permissions"
