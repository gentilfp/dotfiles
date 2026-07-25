# ~/.zshrc — curated, portable zsh. Symlinked from ~/dotfiles/zsh/.zshrc
  # Order matters: options → oh-my-zsh → tools → prompt → local overrides.

  # ── p10k instant prompt (must stay near the top) ─────────────────────────────
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  # ── Homebrew (Apple Silicon or Intel) ────────────────────────────────────────
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

  # ── History ──────────────────────────────────────────────────────────────────
  HISTFILE="$HOME/.zsh_history"
  HISTSIZE=50000
  SAVEHIST=50000
  setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
  setopt SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY
  setopt AUTO_CD INTERACTIVE_COMMENTS

  # ── oh-my-zsh (plugins/completions only; prompt = powerlevel10k, below) ───────
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""                        # p10k is sourced below (Homebrew), not an omz theme
  DISABLE_AUTO_UPDATE="true"
  zstyle ':omz:update' mode disabled
  plugins=(git docker fzf mise)
  [[ -d "$ZSH" ]] && source "$ZSH/oh-my-zsh.sh"

  # ── Dotfiles fragments ───────────────────────────────────────────────────────
  DOTFILES="${DOTFILES:-$HOME/dotfiles}"
  for frag in exports aliases functions; do
    [[ -f "$DOTFILES/zsh/$frag.zsh" ]] && source "$DOTFILES/zsh/$frag.zsh"
  done

  # ── Tools (guarded so a missing tool never breaks the shell) ──────────────────
  command -v mise      >/dev/null && eval "$(mise activate zsh)"
  command -v zoxide    >/dev/null && eval "$(zoxide init zsh)"
  command -v direnv    >/dev/null && eval "$(direnv hook zsh)"

  # fzf keybindings & completion (Ctrl-R, Ctrl-T, Alt-C)
  if command -v fzf >/dev/null; then
    source <(fzf --zsh) 2>/dev/null || true
  fi

  # zsh plugins from Homebrew (order: autosuggestions BEFORE syntax-highlighting)
  [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

  # ── Prompt (powerlevel10k) ───────────────────────────────────────────────────
  [[ -f "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme" ]] && \
    source "$BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"
  [[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

  # ── Machine-specific overrides (secrets, work paths) — NOT tracked ───────────
  [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
