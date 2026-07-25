# zsh/exports.zsh — environment variables & PATH.

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-SRXF"                 # long lines, raw colors, no clear on exit
export CLICOLOR=1

# Language / locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Tool homes
export MISE_NODE_COREPACK=1         # let mise enable corepack for node

# fzf: use fd + a dracula-ish palette, nice defaults
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"

# Personal bin dir first on PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
