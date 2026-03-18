#!/bin/bash
# Auto-sync lablog to git remote
# Called by SessionEnd hook after every Claude session
# Exits silently if no remote configured or nothing to sync

set -euo pipefail

LABLOG_DIR="$HOME/.claude/lablog"
cd "$LABLOG_DIR" || exit 0

# Skip if not a git repo or no remote configured
git rev-parse --git-dir &>/dev/null || exit 0
git remote get-url origin &>/dev/null || exit 0

# Stage all changes
git add -A

# Skip if nothing to commit
git diff --cached --quiet && exit 0

# Commit with machine identifier and timestamp
git commit -m "log $(hostname -s) $(date +%Y-%m-%d_%H:%M)" --no-gpg-sign &>/dev/null

# Pull remote changes (rebase to avoid merge commits), then push
git pull --rebase 2>/dev/null || true
git push 2>/dev/null || true
