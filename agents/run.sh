#!/usr/bin/env bash
# Optional, session-only Caveman proxy. Native harness commands still work.
set -euo pipefail
agent="${1:-}"
case "$agent" in
  codex|pi|claude|opencode) shift ;;
  opencode2) agent=opencode; shift ;;
  *) echo "Usage: agents/run.sh {codex|pi|claude|opencode|opencode2} [args...]" >&2; exit 2 ;;
esac
command -v caveman >/dev/null || { echo "Run agents/setup.sh first." >&2; exit 1; }
exec caveman wrap "$agent" "$@"
