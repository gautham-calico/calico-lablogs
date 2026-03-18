#!/bin/bash
# Setup lablog on any machine - pulls everything from GitHub
#
# Run on any server with one command:
#   bash <(curl -sL https://raw.githubusercontent.com/gautham-calico/calico-lablogs/main/setup-remote.sh)
#
# Or if already cloned:
#   ~/.claude/lablog/setup-remote.sh

set -euo pipefail

REPO_URL="https://github.com/gautham-calico/calico-lablogs.git"
LABLOG_DIR="$HOME/.claude/lablog"
COMMANDS_DIR="$HOME/.claude/commands"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "=== Setting up lablog on $(hostname) ==="

# 1. Clone or update the repo
mkdir -p "$HOME/.claude"

if [ -d "$LABLOG_DIR/.git" ]; then
    echo "[1/4] Repo exists, pulling latest..."
    cd "$LABLOG_DIR" && git pull --rebase 2>/dev/null || true
else
    if [ -d "$LABLOG_DIR" ]; then
        echo "[1/4] Backing up existing lablog dir..."
        mv "$LABLOG_DIR" "${LABLOG_DIR}.bak.$(date +%s)"
    fi
    echo "[1/4] Cloning from GitHub..."
    git clone "$REPO_URL" "$LABLOG_DIR"
fi

# Ensure directory structure
mkdir -p "$LABLOG_DIR/goals/weekly" "$LABLOG_DIR/goals/daily" "$LABLOG_DIR/logs" "$LABLOG_DIR/entries"

# 2. Create slash commands
echo "[2/4] Installing commands (/goals, /log, /benchling)..."
mkdir -p "$COMMANDS_DIR"

cat > "$COMMANDS_DIR/goals.md" << 'CMD_EOF'
---
description: Set daily or weekly research goals
argument-hint: [daily|weekly]
allowed-tools: Read, Write, Bash(date:*), Bash(mkdir:*)
---

## Context

Today's date: !`date +%Y-%m-%d`
Current ISO week: !`date +%Y-W%V`
Day of week: !`date +%A`

## Your task

First, use the date values above to determine file paths, then use the Read tool to check for existing goals:
- Weekly goals file: `~/.claude/lablog/goals/weekly/{ISO_WEEK}.md` (e.g., `2026-W12.md`)
- Daily goals file: `~/.claude/lablog/goals/daily/{DATE}.md` (e.g., `2026-03-18.md`)

Read both files to check if goals already exist (they may not exist yet, that's fine).

The user wants to set their research goals. The argument is: "$1"

**If "$1" is "weekly":**
1. Show existing weekly goals above (if any) and ask if they want to update or replace them
2. Ask the user to type their weekly goals
3. Write them to `~/.claude/lablog/goals/weekly/YYYY-WXX.md` using the current ISO week
4. Format with a header: `# Weekly Goals - YYYY-WXX (date range Mon-Fri)`

**If "$1" is "daily" or empty (default to daily):**
1. Show existing daily goals above (if any) and ask if they want to update or replace them
2. Ask the user to type their daily goals
3. Write them to `~/.claude/lablog/goals/daily/YYYY-MM-DD.md` using today's date
4. Format with a header: `# Daily Goals - YYYY-MM-DD (Day of Week)`

Use bullet points for goals. Keep the interaction concise - show existing goals, ask for new ones, save.
CMD_EOF

cat > "$COMMANDS_DIR/log.md" << 'CMD_EOF'
---
description: Log current session activity to daily lab log
allowed-tools: Read, Write, Edit, Bash(date:*), Bash(mkdir:*)
---

## Context

Today's date: !`date +%Y-%m-%d`
Current time: !`date +%H:%M`
Working directory: !`pwd`
Hostname: !`hostname -s`

## Your task

First, use the date above to check for existing logs by reading `~/.claude/lablog/logs/{DATE}.md` (e.g., `2026-03-18.md`) with the Read tool. The file may not exist yet, that's fine.

Summarize what was accomplished in this Claude session and append it to today's activity log.

1. Review the conversation transcript to identify all substantive work:
   - Code written, modified, or debugged
   - Analysis or research performed
   - Commands run on servers (cluster, gcloud, etc.)
   - Files created or modified
   - Key decisions or findings

2. Append a session entry to `~/.claude/lablog/logs/YYYY-MM-DD.md` (today's date).
   - If the file doesn't exist, create it with header: `# Activity Log - YYYY-MM-DD (Day of Week)`
   - If it exists, append to it

3. Use this format for each session entry:

### Session - HH:MM
**Host:** [hostname/server]  |  **Project:** [project/directory if identifiable]
- Accomplished X
- Debugged Y
- Analyzed Z

Keep bullet points concise but specific enough to be useful in a weekly Benchling entry later.

Do not include any other text besides the tool calls needed to write the log.
CMD_EOF

cat > "$COMMANDS_DIR/benchling.md" << 'CMD_EOF'
---
description: Generate weekly Benchling notebook entry
argument-hint: [week-number]
allowed-tools: Read, Write, Bash(date:*), Bash(ls:*), Bash(cat:*), Bash(git:*)
---

## Context

Today's date: !`date +%Y-%m-%d`
Current ISO week: !`date +%Y-W%V`
Day of week: !`date +%A`

## Available data

Pulling latest logs from all machines: !`git -C ~/.claude/lablog pull --rebase 2>/dev/null; echo "sync complete"`

Weekly goals files: !`ls ~/.claude/lablog/goals/weekly/ 2>/dev/null || echo "none"`
Daily goals files: !`ls ~/.claude/lablog/goals/daily/ 2>/dev/null || echo "none"`
Daily log files: !`ls ~/.claude/lablog/logs/ 2>/dev/null || echo "none"`

## Your task

Generate a complete weekly Benchling notebook entry by compiling goals and daily activity logs.

**Target week:** "$1" (e.g., "W12" or "2026-W12"). If empty, use the current week.

### Steps

1. **Determine the date range** for the target week (Monday through Friday/Sunday)

2. **Read all source files for that week:**
   - Weekly goals: `~/.claude/lablog/goals/weekly/YYYY-WXX.md`
   - Daily goals: `~/.claude/lablog/goals/daily/YYYY-MM-DD.md` for each day
   - Daily logs: `~/.claude/lablog/logs/YYYY-MM-DD.md` for each day

3. **Compile into a structured Benchling entry** using this format:

# Week XX - Mon Date to Fri Date

## Weekly Goals
[from weekly goals file]

## Daily Summary

### Monday (YYYY-MM-DD)
**Goals:**
[from daily goals file]

**Activities:**
[compiled from that day's session logs - consolidate multiple sessions]

### Tuesday (YYYY-MM-DD)
...

## Key Accomplishments
[3-5 major accomplishments synthesized from daily activities]

## Issues / Blockers
[notable issues or items needing follow-up]

## Next Week
[suggested focus areas based on incomplete goals or ongoing work]

4. **Display the compiled entry** for copy-paste into Benchling
5. **Save a copy** to `~/.claude/lablog/entries/YYYY-WXX.md`

If data is missing for some days, note those gaps.
CMD_EOF

# 3. Configure hooks
echo "[3/4] Configuring hooks..."

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "lablog" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  Hooks already configured."
    else
        # Backup existing settings and merge hooks into it
        cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
        # Use python/jq to merge if available, otherwise replace
        if command -v python3 &>/dev/null; then
            python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    settings = json.load(f)
settings['hooks'] = {
    'Stop': [{
        'matcher': '*',
        'hooks': [{
            'type': 'prompt',
            'prompt': 'Check if substantive work was done in this session (code changes, debugging, research, server commands, file edits). If no substantive work was done, respond with {\"ok\": true}. If a file under ~/.claude/lablog/logs/ was already written or edited in this session, respond with {\"ok\": true}. Otherwise respond with {\"ok\": false, \"reason\": \"Auto-log session activity to ~/.claude/lablog/logs/YYYY-MM-DD.md before ending\"}.'
        }]
    }],
    'SessionEnd': [{
        'matcher': '*',
        'hooks': [{
            'type': 'command',
            'command': 'bash ~/.claude/lablog/sync.sh'
        }]
    }]
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
"
            echo "  Hooks merged into existing settings."
        else
            echo "  WARNING: Could not auto-merge hooks (no python3 found)."
            echo "  Backup saved to ${SETTINGS_FILE}.bak"
            echo "  Please manually add hooks. See ~/.claude/lablog/hooks-config.json"
        fi
    fi
else
    cat > "$SETTINGS_FILE" << 'SETTINGS_EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if substantive work was done in this session (code changes, debugging, research, server commands, file edits). If no substantive work was done, respond with {\"ok\": true}. If a file under ~/.claude/lablog/logs/ was already written or edited in this session, respond with {\"ok\": true}. Otherwise respond with {\"ok\": false, \"reason\": \"Auto-log session activity to ~/.claude/lablog/logs/YYYY-MM-DD.md before ending\"}."
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/lablog/sync.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
    echo "  Settings created with hooks."
fi

# 4. Ensure scripts are executable
echo "[4/4] Finalizing..."
chmod +x "$LABLOG_DIR/sync.sh" "$LABLOG_DIR/setup-remote.sh" 2>/dev/null || true

echo ""
echo "=== Setup complete on $(hostname) ==="
echo ""
echo "Commands:  /goals daily  /goals weekly  /log  /benchling"
echo "Auto-log:  sessions auto-log on exit"
echo "Auto-sync: logs push to GitHub on exit"
echo ""
echo "Restart Claude Code for hooks to take effect."
