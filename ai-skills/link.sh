#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=("$HOME/.pi/agent/skills" "$HOME/.claude/skills")

for target in "${TARGETS[@]}"; do
  mkdir -p "$target"
  for skill in "$SRC"/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    ln -sfn "${skill%/}" "$target/$name"
    echo "linked $target/$name -> ${skill%/}"
  done
done
