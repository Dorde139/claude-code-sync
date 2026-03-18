#!/bin/bash
# Auto-sync Claude Code config across PCs
# Called by SessionStart hook in ~/.claude/settings.json
# Bidirectional: captures local → pushes → pulls remote → applies

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCK="$REPO_DIR/.sync-lock"

# Exit silently if not a git repo
[ -d "$REPO_DIR/.git" ] || exit 0

# Lock check — prevent concurrent runs (expire after 60s)
if [ -f "$LOCK" ]; then
    if [ "$(uname -o 2>/dev/null)" = "Msys" ]; then
        lock_age=$(( $(date +%s) - $(date -r "$LOCK" +%s 2>/dev/null || echo 0) ))
    else
        lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    fi
    if [ "$lock_age" -lt 60 ]; then
        exit 0
    fi
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Phase 1: Capture local state into repo
bash "$REPO_DIR/sync-from-claude.sh" >/dev/null 2>&1

# Phase 2: Commit and push local changes
cd "$REPO_DIR" || exit 0
git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
    HOSTNAME_VAL="${COMPUTERNAME:-$(hostname)}"
    git commit -m "auto-sync from $HOSTNAME_VAL $(date +%Y-%m-%d\ %H:%M)" --quiet 2>/dev/null || true
    git push origin main --quiet 2>/dev/null || git push origin master --quiet 2>/dev/null || true
fi

# Phase 3: Pull remote changes
BEFORE=$(git rev-parse HEAD 2>/dev/null)
git pull --rebase --quiet 2>/dev/null || {
    git rebase --abort 2>/dev/null
    exit 0
}
AFTER=$(git rev-parse HEAD 2>/dev/null)

# Phase 4: Apply repo state to local (only if something changed from remote)
if [ "$BEFORE" != "$AFTER" ]; then
    bash "$REPO_DIR/sync-to-claude.sh" >/dev/null 2>&1
fi
