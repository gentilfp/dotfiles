#!/usr/bin/env bash
# Install the shared toolchain and harness adapters on this machine.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

command -v npm >/dev/null || { echo "Install Node.js first (mise install)." >&2; exit 1; }

# Versions tested with this setup. Avoid replacing a working newer installation.
command -v codegraph >/dev/null || npm install -g @colbymchenry/codegraph@1.6.0

"$ROOT/sync.sh" --apply "$@"
echo "Shared setup installed. Restart your harnesses; authenticate Zoku in each."
