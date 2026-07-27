#!/usr/bin/env bash
# bootstrap/lib.sh — shared helpers for the dotfiles installer.
# Sourced by install.sh. Safe to source multiple times.

# ── Colors (disabled when not a TTY) ─────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'
else
  BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""
fi

# ── Logging ──────────────────────────────────────────────────────────────────
header() {
  printf '\n%s┌─ %s%s\n' "$MAGENTA$BOLD" "$1" "$RESET"
}
step()  { printf '%s▸%s %s\n' "$CYAN" "$RESET" "$1"; }
info()  { printf '%s  %s%s\n' "$DIM" "$1" "$RESET"; }
ok()    { printf '%s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
warn()  { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
err()   { printf '%s✗%s %s\n' "$RED" "$RESET" "$1" >&2; }
die()   { err "$1"; exit 1; }

# ── Interaction ──────────────────────────────────────────────────────────────
# ask VAR "Prompt" "default"  → reads a line, echoes the answer (or default).
ask() {
  local prompt="$1" default="${2:-}" reply
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then echo "$default"; return; fi
  if [[ -n "$default" ]]; then
    printf '%s? %s%s [%s]: ' "$BLUE$BOLD" "$prompt" "$RESET" "$default" >&2
  else
    printf '%s? %s%s: ' "$BLUE$BOLD" "$prompt" "$RESET" >&2
  fi
  read -r reply
  echo "${reply:-$default}"
}

# confirm "Prompt" [Y|N]  → returns 0 for yes, 1 for no. Default set by 2nd arg.
confirm() {
  local prompt="$1" default="${2:-Y}" reply hint
  [[ "$default" == "Y" ]] && hint="Y/n" || hint="y/N"
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then [[ "$default" == "Y" ]]; return; fi
  printf '%s? %s%s [%s]: ' "$BLUE$BOLD" "$prompt" "$RESET" "$hint" >&2
  read -r reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# ── Symlinking ───────────────────────────────────────────────────────────────
# link SRC DST — idempotent. Backs up an existing real file/dir to DST.bak-<ts>.
link() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || { warn "skip (missing source): $src"; return; }
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      info "linked already: ${dst/#$HOME/~}"
      return
    fi
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    local bak
    bak="$dst.bak-$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    warn "backed up ${dst/#$HOME/~} → ${bak/#$HOME/~}"
  fi
  ln -s "$src" "$dst"
  ok "linked ${dst/#$HOME/~} → ${src/#$HOME/~}"
}
