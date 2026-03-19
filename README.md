# Calico Lab Log

A lightweight activity logging system for [Claude Code](https://claude.ai/claude-code) that helps you track daily research work and generate weekly Benchling notebook entries. Captures work across all machines (local, cluster, gcloud) and compiles weekly entries.

## Install

### 1. Create your private data repo

Go to [github.com/new](https://github.com/new) and create a **private**, **empty** repo (no README, no license, no .gitignore). Name it whatever you like, e.g. `my-lablog-data`.

### 2. Run the installer

```bash
bash <(curl -sL https://raw.githubusercontent.com/gautham-calico/calico-lablogs/main/setup-remote.sh)
```

It will prompt you to paste your private repo URL. Then restart Claude Code.

### 3. Setup on additional machines

Run the same one-liner on any other machine. If your data repo already exists, it will pull your existing logs automatically.

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
~/.claude/lablog/           # This repo (public) - tools & scripts
  sync.sh                   # Auto-sync script (runs on session end)
  setup-remote.sh           # Installer

~/.claude/lablog-data/      # Private repo - your data
  logs/                     # Daily session logs (YYYY-MM-DD.md)
  goals/
    daily/                  # Daily goals (YYYY-MM-DD.md)
    weekly/                 # Weekly goals (YYYY-WXX.md)
  entries/                  # Compiled Benchling entries (YYYY-WXX.md)
```

## Multi-machine sync

Logs sync automatically via the private GitHub repo. When you run `/benchling`, it pulls the latest logs from all machines before compiling, so your weekly entry includes work from every environment you used.

## Requirements

- [Claude Code](https://claude.ai/claude-code) installed
- Git configured with GitHub access (to both repos)
