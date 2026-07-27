# zsh/aliases.zsh — aliases.

# Editor
alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# eza (modern ls) — fall back gracefully if not installed
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lg --group-directories-first --icons=auto --git'
  alias la='eza -lag --group-directories-first --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
else
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# bat (cat with wings)
command -v bat >/dev/null && alias cat='bat --paging=never'

# git shortcuts
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gsw='git switch'
alias gp='git push'
alias gl='git lg'
alias gd='git diff'
alias lg='lazygit'
alias lzd='lazydocker'

# docker
alias d='docker'
alias dc='docker compose'

# navigation — zoxide replaces cd itself (init --cmd cd in .zshrc), which
# keeps `cd -`, completion, etc. working, unlike an alias to `z`.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# dotfiles: jump to & edit the repo
alias dot='cd ${DOTFILES:-$HOME/dotfiles}'
alias dotfiles='cd ${DOTFILES:-$HOME/dotfiles} && $EDITOR .'

# reload shell
alias reload='exec zsh'

# safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
