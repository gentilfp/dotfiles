#!/usr/bin/env bash
#
#  dotfiles installer — portable macOS dev environment bootstrap.
#
#  Usage:
#    ./install.sh                 interactive
#    ./install.sh --minimal       new-job essentials, no prompts
#    ./install.sh --standard      minimal + cloud & database tooling
#    ./install.sh --full          everything from the reference machine
#    ./install.sh --yes           accept all defaults (implies interactive defaults)
#    ./install.sh --link-only     only (re)create symlinks
#    ./install.sh --doctor        verify the setup (symlinks, tools, mise, git)
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES="$REPO"
source "$REPO/bootstrap/lib.sh"

PROFILE=""            # minimal | standard | full | custom
LINK_ONLY=0
DOCTOR=0
export ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --minimal)   PROFILE="minimal" ;;
    --standard)  PROFILE="standard" ;;
    --full)      PROFILE="full" ;;
    --yes|-y)    ASSUME_YES=1 ;;
    --link-only) LINK_ONLY=1 ;;
    --doctor)    DOCTOR=1 ;;
    -h|--help)   sed -n '3,13p' "$0" | sed 's/^#//'; exit 0 ;;
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

# ── Feature flags (populated by the profile / questions) ─────────────────────
DO_CASKS=0 DO_CLOUD=0 DO_DATA=0 DO_EXTRA=0 DO_CASKS_EXTRA=0
DO_ZSH=0 DO_AI=0 DO_HERD=0 DO_MISE=0

apply_profile() {
  case "$1" in
    minimal)
      DO_CASKS=1 DO_MISE=1 DO_ZSH=1 DO_AI=1 ;;
    standard)
      DO_CASKS=1 DO_CLOUD=1 DO_DATA=1 DO_MISE=1 DO_ZSH=1 DO_AI=1 ;;
    full)
      DO_CASKS=1 DO_CLOUD=1 DO_DATA=1 DO_EXTRA=1 DO_CASKS_EXTRA=1 \
      DO_MISE=1 DO_ZSH=1 DO_AI=1 DO_HERD=1 ;;
  esac
}

choose_profile() {
  header "Choose a profile"
  cat <<EOF
   ${BOLD}1)${RESET} minimal   new-job essentials: core CLI, ghostty, docker, mise, AI CLIs
   ${BOLD}2)${RESET} standard  minimal + cloud & database tooling
   ${BOLD}3)${RESET} full      everything on the reference machine
   ${BOLD}4)${RESET} custom    pick each group yourself
EOF
  local c; c="$(ask "Profile" "1")"
  case "$c" in
    1) PROFILE="minimal"  ;;
    2) PROFILE="standard" ;;
    3) PROFILE="full"     ;;
    4) PROFILE="custom"   ;;
    *) PROFILE="minimal"  ;;
  esac
}

customize() {
  header "Pick your groups"
  confirm "Install GUI apps (ghostty, orbstack, fonts…)?" Y && DO_CASKS=1
  confirm "Install AI coding CLIs (claude, pi, codex)?"    Y && DO_AI=1
  confirm "Set up zsh (oh-my-zsh + powerlevel10k + plugins)?" Y && DO_ZSH=1
  confirm "Install mise runtimes (ruby/node/python/…)?"    Y && DO_MISE=1
  confirm "Install cloud/infra tools (aws, sops, helm…)?"  N && DO_CLOUD=1
  confirm "Install databases (postgres, redis, mailhog)?"  N && DO_DATA=1
  confirm "Install extra CLI tools & fun stuff?"           N && DO_EXTRA=1
  confirm "Install extra GUI apps?"                        N && DO_CASKS_EXTRA=1
  confirm "Install Laravel Herd?"                          N && DO_HERD=1
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

brew_bundle() {
  local file="$REPO/packages/$1"
  [[ -f "$file" ]] || { warn "no such Brewfile: $1"; return; }
  step "brew bundle → $1"
  brew bundle --file="$file" || warn "some entries in $1 failed (continuing)"
}

install_packages() {
  header "Packages"
  if [[ "$PROFILE" == "full" ]]; then
    brew_bundle "Brewfile.full"
    return
  fi
  brew_bundle "Brewfile.core"
  [[ "$DO_CASKS" == 1 ]]       && brew_bundle "Brewfile.casks-core"
  [[ "$DO_CLOUD" == 1 ]]       && brew_bundle "Brewfile.cloud"
  [[ "$DO_DATA"  == 1 ]]       && brew_bundle "Brewfile.data"
  [[ "$DO_EXTRA" == 1 ]]       && brew_bundle "Brewfile.extra"
  [[ "$DO_CASKS_EXTRA" == 1 ]] && brew_bundle "Brewfile.casks-extra"
  [[ "$DO_HERD" == 1 ]]        && { step "installing Herd…"; brew install --cask herd || warn "herd failed"; }
}

# Canonical symlink map — the single source of truth for both linking and
# doctor. Each line: SRC|DST|GROUP   (GROUP is core or zsh).
dotfile_links() {
  printf '%s\n' \
    "$REPO/ghostty|$HOME/.config/ghostty|core" \
    "$REPO/cmux/settings.json|$HOME/.config/cmux/settings.json|core" \
    "$REPO/herdr/config.toml|$HOME/.config/herdr/config.toml|core" \
    "$REPO/nvim|$HOME/.config/nvim|core" \
    "$REPO/git/.gitconfig|$HOME/.gitconfig|core" \
    "$REPO/git/.gitignore|$HOME/.gitignore|core" \
    "$REPO/mise/config.toml|$HOME/.config/mise/config.toml|core" \
    "$REPO/atuin/config.toml|$HOME/.config/atuin/config.toml|core" \
    "$REPO/zsh/.zshrc|$HOME/.zshrc|zsh" \
    "$REPO/zsh/.p10k.zsh|$HOME/.p10k.zsh|zsh"
}

link_dotfiles() {
  header "Symlinks"
  local src dst grp
  while IFS='|' read -r src dst grp; do
    [[ "$grp" == "zsh" && "$DO_ZSH" != 1 ]] && continue
    link "$src" "$dst"
  done < <(dotfile_links)
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
}

install_mise_tools() {
  header "mise runtimes"
  have mise || { warn "mise not installed yet — run packages step first"; return; }
  step "trusting mise config…"
  mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
  mise trust "$REPO/mise/config.toml"          >/dev/null 2>&1 || true
  step "mise install (from ~/.config/mise/config.toml)…"
  mise install || warn "some mise tools failed"
  mise ls
}

install_ai_clis() {
  header "AI coding CLIs"
  # claude-code & codex come via casks (installed with GUI apps). pi via npm.
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
    warn "npm not found — skipping pi (run the mise step first, then re-run --full or install pi manually)"
  fi
}

summary() {
  header "Plan"
  printf '   profile      %s%s%s\n' "$BOLD" "$PROFILE" "$RESET"
  local on="${GREEN}yes${RESET}" off="${DIM}no${RESET}"
  printf '   GUI apps     %s\n' "$([[ $DO_CASKS == 1 ]] && echo "$on" || echo "$off")"
  printf '   AI CLIs      %s\n' "$([[ $DO_AI == 1 ]] && echo "$on" || echo "$off")"
  printf '   zsh setup    %s\n' "$([[ $DO_ZSH == 1 ]] && echo "$on" || echo "$off")"
  printf '   mise tools   %s\n' "$([[ $DO_MISE == 1 ]] && echo "$on" || echo "$off")"
  printf '   cloud/data   %s / %s\n' \
    "$([[ $DO_CLOUD == 1 ]] && echo "$on" || echo "$off")" \
    "$([[ $DO_DATA == 1 ]] && echo "$on" || echo "$off")"
  printf '   extras       %s\n' "$([[ $DO_EXTRA == 1 || $DO_CASKS_EXTRA == 1 ]] && echo "$on" || echo "$off")"
  printf '   Herd         %s\n' "$([[ $DO_HERD == 1 ]] && echo "$on" || echo "$off")"
  echo
}

# ── Doctor ───────────────────────────────────────────────────────────────────
doctor() {
  banner
  local problems=0 src dst grp t

  header "Symlinks"
  while IFS='|' read -r src dst grp; do
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
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  if [[ "$DOCTOR" == 1 ]]; then doctor; exit 0; fi

  banner

  if [[ "$LINK_ONLY" == 1 ]]; then
    DO_ZSH=1; link_dotfiles; ok "done (symlinks only)"; exit 0
  fi

  [[ -z "$PROFILE" ]] && choose_profile
  apply_profile "$PROFILE"
  [[ "$PROFILE" == "custom" ]] && customize

  summary
  confirm "Proceed?" Y || { warn "aborted"; exit 0; }

  ensure_xcode_clt
  ensure_homebrew
  install_packages
  link_dotfiles
  [[ "$DO_ZSH"  == 1 ]] && setup_zsh
  setup_git_identity
  [[ "$DO_MISE" == 1 ]] && install_mise_tools
  [[ "$DO_AI"   == 1 ]] && install_ai_clis

  header "Done 🎉"
  ok "Open a new terminal (or run: exec zsh) to load everything."
  info "Next: open nvim to let lazy.nvim sync plugins, then 'mise doctor'."
}

main "$@"
