#!/bin/bash
# Syncs dotfiles repo → local machine
# Applies: global config, skills, .env (decrypted), settings.local.json, memory
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/projects.conf"

REPO_CONFIG="$SCRIPT_DIR/claude-config"
REPO_ENV="$SCRIPT_DIR/project-env"
REPO_SETTINGS="$SCRIPT_DIR/project-settings"
REPO_MEMORY="$SCRIPT_DIR/project-memory"

echo "=== sync-to-claude: repo → local ==="

# --- Global Claude config ---
echo "  Global config..."
mkdir -p "$CLAUDE_DIR/skills"
cp "$REPO_CONFIG/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null || true
cp "$REPO_CONFIG/settings.local.json" "$CLAUDE_DIR/settings.local.json" 2>/dev/null || true
cp "$REPO_CONFIG/keybindings.json" "$CLAUDE_DIR/keybindings.json" 2>/dev/null || true

for skill_dir in "$REPO_CONFIG/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null || true
done

# --- Per-project files ---
for entry in "${PROJECTS[@]}"; do
    name="${entry%%|*}"
    encoded="${entry##*|}"
    project_dir="$CODE_DIR/$name"

    echo "  Project: $name"

    # .env (decrypt from encrypted store)
    if [ -d "$project_dir" ] && [ -f "$REPO_ENV/$name.env.enc" ] && [ -f "$SCRIPT_DIR/.sync-key" ]; then
        key_path=$(cygpath -w "$SCRIPT_DIR/.sync-key" 2>/dev/null || echo "$SCRIPT_DIR/.sync-key")
        openssl enc -aes-256-cbc -d -pbkdf2 \
            -in "$REPO_ENV/$name.env.enc" \
            -out "$project_dir/.env" \
            -pass "file:$key_path" 2>/dev/null
    fi

    # settings.local.json
    if [ -f "$REPO_SETTINGS/$name.json" ]; then
        mkdir -p "$project_dir/.claude"
        cp "$REPO_SETTINGS/$name.json" "$project_dir/.claude/settings.local.json"
    fi

    # Memory
    if [ -n "$encoded" ] && [ -d "$REPO_MEMORY/$name" ]; then
        mkdir -p "$CLAUDE_DIR/projects/$encoded/memory"
        cp "$REPO_MEMORY/$name/"* "$CLAUDE_DIR/projects/$encoded/memory/" 2>/dev/null || true
    fi
done

echo "=== Done: local machine updated from dotfiles repo ==="
