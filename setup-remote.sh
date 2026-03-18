#!/bin/bash
# Setup lablog on a remote machine
# Usage: curl/scp this script to the remote machine and run it
#   ./setup-remote.sh <git-repo-url>
#
# Example:
#   ./setup-remote.sh git@github.com:gautham/lablog.git

set -euo pipefail

REPO_URL="${1:-}"

if [ -z "$REPO_URL" ]; then
    echo "Usage: ./setup-remote.sh <git-repo-url>"
    echo "Example: ./setup-remote.sh git@github.com:youruser/lablog.git"
    exit 1
fi

echo "=== Setting up lablog on $(hostname) ==="

# 1. Clone or update lablog repo
LABLOG_DIR="$HOME/.claude/lablog"
if [ -d "$LABLOG_DIR/.git" ]; then
    echo "Lablog repo already exists, pulling latest..."
    cd "$LABLOG_DIR" && git pull
else
    echo "Cloning lablog repo..."
    mkdir -p "$HOME/.claude"
    # If directory exists but isn't a repo, back it up
    if [ -d "$LABLOG_DIR" ]; then
        mv "$LABLOG_DIR" "${LABLOG_DIR}.bak.$(date +%s)"
    fi
    git clone "$REPO_URL" "$LABLOG_DIR"
fi

# 2. Ensure directory structure exists
mkdir -p "$LABLOG_DIR/goals/weekly" "$LABLOG_DIR/goals/daily" "$LABLOG_DIR/logs" "$LABLOG_DIR/entries"

# 3. Create commands directory and command files
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"

# /goals command
cat > "$COMMANDS_DIR/goals.md" << 'GOALEOF'
---
description: Set daily or weekly research goals
argument-hint: [daily|weekly]
allowed-tools: Read, Write, Bash(date:*), Bash(mkdir:*)
---

## Context

Today's date: !`date +%Y-%m-%d`
Current ISO week: !`date +%Y-W%V`
Day of week: !`date +%A`

## Existing goals

Weekly goals for this week (if any): !`cat ~/.claude/lablog/goals/weekly/$(date +%Y-W%V).md 2>/dev/null || echo "No weekly goals set yet"`

Daily goals for today (if any): !`cat ~/.claude/lablog/goals/daily/$(date +%Y-%m-%d).md 2>/dev/null || echo "No daily goals set yet"`

## Your task

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
GOALEOF

# /log command
cat > "$COMMANDS_DIR/log.md" << 'LOGEOF'
---
description: Log current session activity to daily lab log
allowed-tools: Read, Write, Edit, Bash(date:*), Bash(mkdir:*)
---

## Context

Today's date: !`date +%Y-%m-%d`
Current time: !`date +%H:%M`
Working directory: !`pwd`
Hostname: !`hostname -s`

Existing log for today (if any): !`cat ~/.claude/lablog/logs/$(date +%Y-%m-%d).md 2>/dev/null || echo "No log entries yet today"`

## Your task

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
LOGEOF

# /benchling command
cat > "$COMMANDS_DIR/benchling.md" << 'BENCHEOF'
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

Pull latest from all machines first: !`cd ~/.claude/lablog && git pull --rebase 2>/dev/null; echo "sync done"`

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
BENCHEOF

# 4. Configure hooks in settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Check if hooks already configured
    if grep -q "lablog" "$SETTINGS_FILE" 2>/dev/null; then
        echo "Hooks already configured in settings.json"
    else
        echo "NOTE: Please add hooks to $SETTINGS_FILE manually."
        echo "See ~/.claude/lablog/hooks-config.json for the config to merge."
    fi
else
    cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the conversation transcript. If substantive work was done in this session (code changes, analysis, debugging, research, server commands, file operations, etc.) AND no write or edit to any file under ~/.claude/lablog/logs/ has been made yet in this session, then BLOCK with reason: 'Auto-logging: Before ending, append a brief session summary to ~/.claude/lablog/logs/YYYY-MM-DD.md (use today actual date). Create the file with header \"# Activity Log - YYYY-MM-DD (DayOfWeek)\" if it does not exist. Format the entry as: ### Session - HH:MM followed by **Host:** hostname | **Project:** project/dir, then 3-5 concise bullet points of what was accomplished. Use the Write or Edit tool.' If a log entry was already written to ~/.claude/lablog/logs/ in this session, OR if no substantive work was done (e.g. just greetings, questions about Claude, or trivial interactions), then APPROVE and let the session end."
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
SETTINGSEOF
fi

# Make scripts executable
chmod +x "$LABLOG_DIR/sync.sh"
chmod +x "$LABLOG_DIR/setup-remote.sh"

echo ""
echo "=== Setup complete on $(hostname) ==="
echo "Commands available: /goals, /log, /benchling"
echo "Auto-logging: enabled (Stop hook)"
echo "Auto-sync: enabled (SessionEnd hook)"
echo ""
echo "Restart Claude Code for hooks to take effect."
