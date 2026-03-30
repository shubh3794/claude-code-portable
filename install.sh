#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
ECC_DIR="$HOME/everything-claude-code"

echo "=== Claude Code Portable Installer ==="
echo ""
echo "  Target:    $CLAUDE_DIR"
echo "  ECC:       $ECC_DIR"
echo ""

# -------------------------------------------------------
# Step 1: Prerequisites
# -------------------------------------------------------
echo "[1/5] Checking prerequisites..."

if ! command -v node &>/dev/null; then
  echo "  ERROR: node not found. Install Node.js first."
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "  ERROR: claude not found. Install Claude Code first."
  echo "  https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

echo "  node $(node --version), claude found."

# -------------------------------------------------------
# Step 2: Install ECC (everything-claude-code)
# -------------------------------------------------------
echo "[2/5] Setting up ECC..."

if [ -d "$ECC_DIR/.git" ]; then
  echo "  ECC already cloned at $ECC_DIR. Pulling latest..."
  git -C "$ECC_DIR" pull --ff-only 2>/dev/null || echo "  (pull skipped — local changes or offline)"
else
  echo "  Cloning everything-claude-code..."
  git clone https://github.com/affaan-m/everything-claude-code.git "$ECC_DIR"
fi

# Run ECC's own installer if it exists
if [ -x "$ECC_DIR/install.sh" ]; then
  echo "  Running ECC installer..."
  cd "$ECC_DIR" && bash install.sh
  cd "$SCRIPT_DIR"
fi

# -------------------------------------------------------
# Step 3: Install GSD (get-shit-done-cc)
# -------------------------------------------------------
echo "[3/5] Setting up GSD..."

if [ -f "$CLAUDE_DIR/get-shit-done/VERSION" ]; then
  CURRENT_GSD=$(cat "$CLAUDE_DIR/get-shit-done/VERSION")
  echo "  GSD v${CURRENT_GSD} already installed."
else
  echo "  Installing get-shit-done-cc via npm..."
  npm install -g get-shit-done-cc 2>/dev/null || echo "  (npm install failed — install manually: npm install -g get-shit-done-cc)"
fi

# -------------------------------------------------------
# Step 4: Overlay custom files
# -------------------------------------------------------
echo "[4/5] Copying custom files..."

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

# Fix hardcoded home paths in all .md files
echo "  Fixing hardcoded paths → $CLAUDE_DIR/"
for search_dir in "$CLAUDE_DIR/get-shit-done" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/rules"; do
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
# Step 5: Generate settings.json
# -------------------------------------------------------
echo "[5/5] Generating settings.json..."

if [ -f "$CLAUDE_DIR/settings.json" ]; then
  BACKUP="$CLAUDE_DIR/settings.json.bak.$(date +%s)"
  cp "$CLAUDE_DIR/settings.json" "$BACKUP"
  echo "  Backed up existing → $(basename "$BACKUP")"
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
echo "=== Done! ==="
echo ""
echo "Run Claude with ECC:"
echo "  claude --plugin-dir $ECC_DIR --dangerously-skip-permissions"
echo ""
echo "Or add an alias to your shell:"
echo "  alias cc='claude --plugin-dir $ECC_DIR --dangerously-skip-permissions'"
