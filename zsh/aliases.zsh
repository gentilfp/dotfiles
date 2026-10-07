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

# MOSS colors for eza (truecolor). Muted greens and greys; red only for the
# destructive-looking bits. Hexes from moss/tokens/moss.json.
export EZA_COLORS="reset:\
di=38;2;126;146;115:ln=38;2;154;153;104:ex=38;2;182;154;100:\
ur=38;2;182;154;100:uw=38;2;167;93;87:ux=38;2;126;146;115:ue=38;2;126;146;115:\
gr=38;2;182;154;100:gw=38;2;167;93;87:gx=38;2;126;146;115:\
tr=38;2;182;154;100:tw=38;2;167;93;87:tx=38;2;126;146;115:\
sn=38;2;154;153;104:sb=38;2;112;118;107:uu=38;2;154;153;104:un=38;2;167;93;87:\
gu=38;2;112;118;107:gn=38;2;167;93;87:da=38;2;112;118;107:\
ga=38;2;126;146;115:gm=38;2;182;154;100:gd=38;2;167;93;87:gv=38;2;154;153;104:gt=38;2;75;81;71:\
lc=38;2;75;81;71:xa=38;2;75;81;71:hd=38;2;112;118;107:\
sn=38;2;154;153;104:uu=38;2;154;153;104"
