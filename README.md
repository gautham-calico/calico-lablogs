# Calico Lab Logs

Automated research logging system for Benchling notebook entries. Captures work across all servers (local, cluster, gcloud) and compiles weekly entries.

## Setup

Run this on any machine with Claude Code:

```bash
bash <(curl -sL https://raw.githubusercontent.com/gautham-calico/calico-lablogs/main/setup-remote.sh)
```

Then restart Claude Code for hooks to take effect.

## Commands

| Command | Description |
|---------|-------------|
| `/goals weekly` | Set weekly research goals |
| `/goals daily` | Set daily research goals |
| `/log` | Manually log current session activity |
| `/benchling` | Generate weekly Benchling notebook entry |
| `/benchling W12` | Generate entry for a specific week |

## How it works

- **Auto-logging**: A Stop hook captures a session summary before every Claude session ends
- **Auto-sync**: A SessionEnd hook pushes logs to this repo after every session
- **Cross-machine**: All servers push to this repo; `/benchling` pulls from all machines before compiling

## Directory structure

```
goals/
  weekly/    # 2026-W12.md, etc.
  daily/     # 2026-03-18.md, etc.
logs/        # Daily session logs (auto-appended)
entries/     # Compiled weekly Benchling entries
```

## Workflow

1. **Monday morning**: `/goals weekly` then `/goals daily`
2. **Each morning**: `/goals daily`
3. **Throughout the day**: Work normally - sessions auto-log on exit
4. **End of week**: `/benchling` - copy output into Benchling
