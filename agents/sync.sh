#!/usr/bin/env bash
# Link every skill in skills/ into each harness skill directory.
#
#   sync.sh                             preview changes
#   sync.sh --apply                     create and refresh links
#   sync.sh --check                     preview; exit 1 when links have drifted
#   sync.sh --apply --exclude 'zok-*'   skip skills matching GLOB; repeatable
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$root/skills"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

targets=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.pi/agent/skills"
  "$config_home/opencode/skills"
)
# Typo directory created by the retired linker; removed when it only holds our links.
legacy_dir="$HOME/.claude/skills,"

usage() {
  cat <<'EOF'
Usage: sync.sh [--apply] [--check] [--exclude GLOB]...

  --apply          create and refresh skill links; without it nothing is written
  --check          exit nonzero when the links have drifted from this repository
  --exclude GLOB   skip skills matching GLOB and unlink them if linked; repeatable
EOF
}

apply=0
check=0
excludes=()

while (($#)); do
  case "$1" in
    --apply) apply=1 ;;
    --check) check=1 ;;
    --exclude)
      shift
      if (($# == 0)); then
        echo "sync.sh: --exclude needs a GLOB" >&2
        exit 2
      fi
      excludes+=("$1")
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "sync.sh: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ((apply && check)); then
  echo "sync.sh: use either --apply or --check, not both" >&2
  exit 2
fi

shopt -s nullglob

skills=()
for dir in "$source_dir"/*/; do
  name="${dir%/}"
  name="${name##*/}"
  [[ -f "$dir/SKILL.md" ]] || continue
  skip=0
  for pattern in ${excludes[@]+"${excludes[@]}"}; do
    if [[ "$name" == $pattern ]]; then
      skip=1
      break
    fi
  done
  if ((skip)); then
    continue
  fi
  skills+=("$name")
done

if ((${#skills[@]} == 0)); then
  echo "sync.sh: no skills found under $source_dir" >&2
  exit 1
fi

is_desired() {
  local wanted="$1" name
  for name in "${skills[@]}"; do
    if [[ "$name" == "$wanted" ]]; then
      return 0
    fi
  done
  return 1
}

# True when a symlink resolves into this repository's skills directory, which
# means sync.sh created it and may remove it again.
owned_link() {
  local link="$1" raw dir resolved
  raw="$(readlink "$link")" || return 1
  if [[ "$raw" == /* ]]; then
    resolved="$raw"
  else
    dir="$(cd "$(dirname "$link")" 2>/dev/null && cd "$(dirname "$raw")" 2>/dev/null && pwd)" || return 1
    resolved="$dir/$(basename "$raw")"
  fi
  [[ "$resolved" == "$source_dir"/* ]]
}

kinds=()
paths=()

plan() {
  kinds+=("$1")
  paths+=("$2")
}

for target in "${targets[@]}"; do
  if [[ -d "$target" ]]; then
    for entry in "$target"/*; do
      [[ -L "$entry" ]] || continue
      owned_link "$entry" || continue
      name="${entry##*/}"
      if is_desired "$name" && [[ "$(readlink "$entry")" == "$source_dir/$name" ]]; then
        continue
      fi
      plan unlink "$entry"
    done
  fi

  for name in "${skills[@]}"; do
    dest="$target/$name"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$source_dir/$name" ]]; then
      continue
    fi
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      echo "sync.sh: $dest exists and is not a symlink; move it aside and re-run" >&2
      exit 1
    fi
    plan link "$dest"
  done
done

if [[ -d "$legacy_dir" ]]; then
  leftovers=0
  for entry in "$legacy_dir"/*; do
    if [[ -L "$entry" ]] && owned_link "$entry"; then
      plan unlink "$entry"
    else
      leftovers=1
    fi
  done
  if ((leftovers == 0)); then
    plan rmdir "$legacy_dir"
  fi
fi

count=${#kinds[@]}
index=0
while ((index < count)); do
  kind="${kinds[index]}"
  path="${paths[index]}"
  case "$kind" in
    link)
      printf 'link:   %s -> %s\n' "$path" "$source_dir/${path##*/}"
      if ((apply)); then
        mkdir -p -- "${path%/*}"
        rm -f -- "$path"
        ln -s "$source_dir/${path##*/}" "$path"
      fi
      ;;
    unlink)
      printf 'unlink: %s\n' "$path"
      if ((apply)); then
        rm -f -- "$path"
      fi
      ;;
    rmdir)
      printf 'rmdir:  %s\n' "$path"
      if ((apply)); then
        rmdir -- "$path" 2>/dev/null || true
      fi
      ;;
  esac
  index=$((index + 1))
done

if ((count == 0)); then
  echo "Skills already in sync."
  exit 0
fi
if ((apply)); then
  echo "$count change(s) applied"
  exit 0
fi
echo "$count change(s) pending; re-run with --apply"
if ((check)); then
  exit 1
fi
