# Statusline

Custom statusline bars shared across harnesses. Each tool has its own
rendering mechanism, so there is one implementation per harness instead of a
single shared script. `sync.py` symlinks these into the harness config dirs;
the wiring never touches the repo.

## Components

| Harness | Source | Installed at | Wiring |
|---|---|---|---|
| Claude Code | `claude/statusline.sh` | `~/.claude/statusline.sh` | `statusLine.command` in `~/.claude/settings.json` |
| Pi | `pi/aij-footer/` | `~/.pi/agent/extensions/aij-footer` | Pi auto-loads extensions from `~/.pi/agent/extensions` |

## Claude Code

Bash script that reads the statusLine JSON payload from stdin and prints two
lines: `directory · model (effort)` and `5h/7d remaining % (resets …)`.
Requires `jq`. The `statusLine` block in `settings.json` is not managed by
`sync.py`; if you set up a new machine from scratch, add it manually:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

## Pi (AI Juice footer)

TypeScript extension (`index.ts` + `test.mjs`) that renders a footer with the
current directory, model, thinking level, and AI Juice usage. Run
`/reload` in Pi after installing or editing it. See `pi/aij-footer/README.md`.

The extension only renders when `aij` (AI Juice) is installed. It prefers
`~/.local/bin/aij` and falls back to `aij` on PATH.

## Editing

Edit the files here, commit, and on each machine run
`git pull --ff-only && just agents-sync`. The first sync on an existing
machine backs up the current `~/.claude/statusline.sh` and
`~/.pi/agent/extensions/aij-footer` before replacing them with symlinks
(see `~/.local/state/dotfiles-agents/backups`).