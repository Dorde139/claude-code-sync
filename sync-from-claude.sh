#!/bin/bash
# Syncs local machine state → dotfiles repo
# Captures: global config, skills, .env (encrypted), settings.local.json, memory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/projects.conf"

REPO_CONFIG="$SCRIPT_DIR/claude-config"
REPO_ENV="$SCRIPT_DIR/project-env"
REPO_SETTINGS="$SCRIPT_DIR/project-settings"
REPO_MEMORY="$SCRIPT_DIR/project-memory"

echo "=== sync-from-claude: local → repo ==="

# --- Global Claude config ---
echo "  Global config..."
mkdir -p "$REPO_CONFIG/skills"
cp "$CLAUDE_DIR/settings.json" "$REPO_CONFIG/settings.json" 2>/dev/null || true
cp "$CLAUDE_DIR/settings.local.json" "$REPO_CONFIG/settings.local.json" 2>/dev/null || true
cp "$CLAUDE_DIR/keybindings.json" "$REPO_CONFIG/keybindings.json" 2>/dev/null || true

for skill_dir in "$CLAUDE_DIR/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$REPO_CONFIG/skills/$skill_name"
    cp "$skill_dir"* "$REPO_CONFIG/skills/$skill_name/" 2>/dev/null || true
done

# --- Per-project files ---
for entry in "${PROJECTS[@]}"; do
    name="${entry%%|*}"
    encoded="${entry##*|}"
    project_dir="$CODE_DIR/$name"

    echo "  Project: $name"

    # .env (encrypted with openssl)
    if [ -f "$project_dir/.env" ] && [ -f "$SCRIPT_DIR/.sync-key" ]; then
        mkdir -p "$REPO_ENV"
        key_path=$(cygpath -w "$SCRIPT_DIR/.sync-key" 2>/dev/null || echo "$SCRIPT_DIR/.sync-key")
        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$project_dir/.env" \
            -out "$REPO_ENV/$name.env.enc" \
            -pass "file:$key_path" 2>/dev/null
    fi

    # settings.local.json
    if [ -f "$project_dir/.claude/settings.local.json" ]; then
        mkdir -p "$REPO_SETTINGS"
        cp "$project_dir/.claude/settings.local.json" "$REPO_SETTINGS/$name.json"
    fi

    # Memory (delete-and-replace to propagate deletions)
    if [ -n "$encoded" ] && [ -d "$CLAUDE_DIR/projects/$encoded/memory" ]; then
        rm -rf "$REPO_MEMORY/$name"
        mkdir -p "$REPO_MEMORY/$name"
        cp "$CLAUDE_DIR/projects/$encoded/memory/"* "$REPO_MEMORY/$name/" 2>/dev/null || true
    fi
done

echo "=== Done: dotfiles repo updated from local state ==="
