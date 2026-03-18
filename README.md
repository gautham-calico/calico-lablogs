# Calico Lab Log

A lightweight activity logging system for [Claude Code](https://claude.ai/claude-code) that helps you track daily research work and generate weekly Benchling notebook entries. Captures work across all machines (local, cluster, gcloud) and compiles weekly entries.

## Install

Run this one-liner on any machine with Claude Code:

```bash
bash <(curl -sL https://raw.githubusercontent.com/gautham-calico/calico-lablogs/main/setup-remote.sh)
```

Then restart Claude Code.

## Commands

| Command | Description |
|---------|-------------|
| `/log` | Log your current session's activity. **Run this before exiting each session.** |
| `/goals daily` | Set daily research goals |
| `/goals weekly` | Set weekly research goals |
| `/benchling` | Compile the current week's logs into a Benchling notebook entry |
| `/benchling W11` | Compile a specific week's entry |

## Workflow

1. **Monday morning**: `/goals weekly` then `/goals daily`
2. **Each morning**: `/goals daily`
3. **Before exiting a session**: type `/log` -- Claude reviews the session and saves a summary
4. **End of week**: `/benchling` -- copy the output into Benchling

Logs are automatically pushed to GitHub when your session ends, so your work is synced across machines without any extra steps.

## What gets logged

Each `/log` entry captures:
- Code written, modified, or debugged
- Analysis or research performed
- Commands run on servers (cluster, gcloud, etc.)
- Files created or modified
- Key decisions or findings

## Data structure

```
~/.claude/lablog/
  logs/           # Daily session logs (YYYY-MM-DD.md)
  goals/
    daily/        # Daily goals (YYYY-MM-DD.md)
    weekly/       # Weekly goals (YYYY-WXX.md)
  entries/        # Compiled Benchling entries (YYYY-WXX.md)
  sync.sh         # Auto-sync script (runs on session end)
  setup-remote.sh # Installer
```

## Multi-machine sync

Logs sync automatically via this GitHub repo. When you run `/benchling`, it pulls the latest logs from all machines before compiling, so your weekly entry includes work from every environment you used.

## Requirements

- [Claude Code](https://claude.ai/claude-code) installed
- Git configured with GitHub access
