#!/usr/bin/env bash
#
#  dotfiles installer — one command, one setup: a new work machine.
#
#  Usage:
#    ./install.sh                 install everything (asks only what it must)
#    ./install.sh --yes           no prompts, accept all defaults
#    ./install.sh --link-only     only (re)create symlinks
#    ./install.sh --doctor        verify the setup (symlinks, tools, mise, git)
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES="$REPO"
source "$REPO/bootstrap/lib.sh"

LINK_ONLY=0
DOCTOR=0
export ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --yes|-y)    ASSUME_YES=1 ;;
    --link-only) LINK_ONLY=1 ;;
    --doctor)    DOCTOR=1 ;;
    -h|--help)   sed -n '3,10p' "$0" | sed 's/^#//'; exit 0 ;;
    *) die "unknown argument: $arg" ;;
  esac
done

banner() {
  printf '%s' "$MAGENTA$BOLD"
  cat <<'ART'
   ┌─────────────────────────────────────────┐
   │   ▓ dotfiles bootstrap                   │
   │   ghostty · nvim · mise · docker · AI    │
   └─────────────────────────────────────────┘
ART
  printf '%s' "$RESET"
  info "repo: $REPO"
}

# ── Steps ────────────────────────────────────────────────────────────────────
ensure_xcode_clt() {
  header "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then ok "already installed"; return; fi
  step "requesting Command Line Tools install…"
  xcode-select --install 2>/dev/null || true
  warn "Finish the macOS installer dialog that just opened."
  info "Waiting for CLT to finish installing… (Ctrl-C to abort)"
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "Command Line Tools ready"
}

ensure_homebrew() {
  header "Homebrew"
  if have brew; then ok "already installed ($(brew --version | head -1))"; return; fi
  step "installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  ok "Homebrew ready"
}

install_packages() {
  header "Packages"
  step "brew bundle → packages/Brewfile"
  brew bundle --file="$REPO/packages/Brewfile" || warn "some Brewfile entries failed (continuing)"
}

# Canonical symlink map — the single source of truth for both linking and
# doctor. Each line: SRC|DST
dotfile_links() {
  printf '%s\n' \
    "$REPO/ghostty|$HOME/.config/ghostty" \
    "$REPO/cmux/settings.json|$HOME/.config/cmux/settings.json" \
    "$REPO/herdr/config.toml|$HOME/.config/herdr/config.toml" \
    "$REPO/nvim|$HOME/.config/nvim" \
    "$REPO/git/.gitconfig|$HOME/.gitconfig" \
    "$REPO/git/.gitignore|$HOME/.gitignore" \
    "$REPO/mise/config.toml|$HOME/.config/mise/config.toml" \
    "$REPO/atuin/config.toml|$HOME/.config/atuin/config.toml" \
    "$REPO/zsh/.zshrc|$HOME/.zshrc" \
    "$REPO/zsh/.p10k.zsh|$HOME/.p10k.zsh"
}

link_dotfiles() {
  header "Symlinks"
  local src dst
  while IFS='|' read -r src dst; do
    link "$src" "$dst"
  done < <(dotfile_links)
  return 0
}

setup_git_identity() {
  header "Git identity"
  local local_cfg="$HOME/.gitconfig.local"
  if [[ -f "$local_cfg" ]] && ! confirm "Overwrite existing ~/.gitconfig.local?" N; then
    info "keeping existing identity"; return
  fi
  local name email
  name="$(ask "Git user.name"  "$(git config --global user.name  2>/dev/null || echo)")"
  email="$(ask "Git user.email" "$(git config --global user.email 2>/dev/null || echo)")"
  cat >"$local_cfg" <<EOF
# Machine/job-specific git identity — NOT tracked in dotfiles.
[user]
	name = $name
	email = $email
EOF
  ok "wrote $local_cfg  ($name <$email>)"
}

setup_zsh() {
  header "Zsh"
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    step "installing oh-my-zsh…"
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || warn "omz install failed"
  else
    ok "oh-my-zsh present"
  fi
  # Ensure a local override file exists (never tracked)
  [[ -f "$HOME/.zshrc.local" ]] || { echo "# machine-specific zsh overrides" >"$HOME/.zshrc.local"; ok "created ~/.zshrc.local"; }
  if [[ "${SHELL:-}" != *zsh ]]; then
    confirm "Make zsh your default shell?" Y && chsh -s "$(command -v zsh)" || true
  fi
  return 0
}

install_mise_tools() {
  header "mise runtimes"
  have mise || { warn "mise not installed yet — run packages step first"; return; }
  step "trusting mise config…"
  mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
  mise trust "$REPO/mise/config.toml"          >/dev/null 2>&1 || true
  step "mise install (from ~/.config/mise/config.toml)…"
  mise install || warn "some mise tools failed"
  mise ls || warn "mise ls failed"
  return 0
}

install_ai_clis() {
  header "AI coding CLIs"
  # claude-code & codex come via casks (installed with the Brewfile). pi via npm.
  if have brew; then
    have claude 2>/dev/null || brew install --cask claude-code || warn "claude-code failed"
    have codex  2>/dev/null || brew install --cask codex        || warn "codex failed"
  fi
  if have pi; then
    ok "pi already installed"
  elif have npm; then
    step "installing pi (npm)…"
    # --ignore-scripts is safe: pi ships pre-built with no install lifecycle hooks.
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent || warn "pi install failed"
  else
    warn "npm not found — skipping pi (run the mise step first, then re-run ./install.sh or install pi manually)"
  fi
  return 0
}

# ── Doctor ───────────────────────────────────────────────────────────────────
doctor() {
  banner
  local problems=0 src dst t

  header "Symlinks"
  while IFS='|' read -r src dst; do
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      ok "${dst/#$HOME/~}"
    elif [[ -e "$dst" ]]; then
      warn "${dst/#$HOME/~} exists but is NOT linked to the repo"; problems=$((problems+1))
    else
      warn "${dst/#$HOME/~} missing"; problems=$((problems+1))
    fi
  done < <(dotfile_links)

  header "Required tools"
  for t in brew git nvim mise fzf rg fd bat eza zoxide atuin gh lazygit; do
    if have "$t"; then ok "$t"; else warn "$t missing"; problems=$((problems+1)); fi
  done

  header "Terminal & AI (optional)"
  for t in cmux herdr claude codex pi docker; do
    if have "$t"; then ok "$t"; else info "$t not installed"; fi
  done

  header "mise & git"
  if have mise; then
    if mise ls >/dev/null 2>&1; then
      ok "mise config readable & trusted"
    else
      warn "mise config not trusted → run: mise trust"; problems=$((problems+1))
    fi
  fi
  if [[ -f "$HOME/.gitconfig.local" ]]; then
    ok "git identity: $(git config user.email 2>/dev/null || echo '?')"
  else
    warn "no ~/.gitconfig.local — run ./install.sh to set your identity"; problems=$((problems+1))
  fi

  echo
  if (( problems == 0 )); then ok "all good ✓"; else warn "$problems issue(s) found"; fi
  return $(( problems > 0 ? 1 : 0 ))
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  if [[ "$DOCTOR" == 1 ]]; then doctor; exit $?; fi

  banner

  if [[ "$LINK_ONLY" == 1 ]]; then
    link_dotfiles; ok "done (symlinks only)"; exit 0
  fi

  confirm "Set up this machine (packages, symlinks, zsh, mise, AI CLIs)?" Y || { warn "aborted"; exit 0; }

  ensure_xcode_clt
  ensure_homebrew
  install_packages
  link_dotfiles
  setup_zsh
  setup_git_identity
  install_mise_tools
  install_ai_clis

  header "Done 🎉"
  ok "Open a new terminal (or run: exec zsh) to load everything."
  info "Next: open nvim to let lazy.nvim sync plugins, then 'mise doctor'."
}

main "$@"
