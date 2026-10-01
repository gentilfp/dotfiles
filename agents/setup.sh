#!/usr/bin/env bash
# Install the shared toolchain and native RTK adapters on this machine.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

command -v uv >/dev/null || { echo "Install uv first (brew install uv)." >&2; exit 1; }
command -v npm >/dev/null || { echo "Install Node.js first (mise install)." >&2; exit 1; }
if ! command -v rtk >/dev/null; then
  command -v brew >/dev/null || { echo "Install RTK: https://github.com/rtk-ai/rtk" >&2; exit 1; }
  brew install rtk
fi

# Versions tested with this setup. Avoid replacing a working newer installation.
command -v codegraph >/dev/null || npm install -g @colbymchenry/codegraph@1.6.0

"$ROOT/sync.sh" --apply "$@"
# Snapshot files owned by RTK before asking its installer to update them.
backup="$(mktemp -d "$HOME/.local/state/dotfiles-agents/rtk-backup-XXXXXX")"
for file in .claude/settings.json .claude/CLAUDE.md .claude/RTK.md \
            .codex/AGENTS.md .codex/RTK.md .codex/hooks.json \
            .pi/agent/extensions/rtk.ts; do
  if [[ -f "$HOME/$file" ]]; then
    mkdir -p "$backup/$(dirname "$file")"
    cp -p "$HOME/$file" "$backup/$file"
  fi
done
opencode_plugin="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins/rtk.ts"
[[ ! -f "$opencode_plugin" ]] || cp -p "$opencode_plugin" "$backup/opencode-rtk.ts"
echo "RTK adapter backups: $backup"
# Let RTK own its adapters rather than maintaining four copied implementations.
rtk init -g --auto-patch
rtk init -g --codex
rtk init -g --agent pi
rtk init -g --opencode --auto-patch
# RTK may edit instruction files; restore the shared block if needed.
"$ROOT/sync.sh" --apply "$@"
echo "Shared setup installed. Restart your harnesses; authenticate Zoku in each."
