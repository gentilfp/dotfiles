# zsh/functions.zsh — small shell functions.

# mkcd: make a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# up: go up N directories (default 1) — `up 3`
up() {
  local n="${1:-1}" p=""
  for _ in $(seq 1 "$n"); do p="../$p"; done
  cd "$p" || return
}

# gclone: clone and cd into the repo
gclone() { git clone "$1" && cd "$(basename "${1%.git}")"; }

# fkill: fuzzy-pick a process and kill it
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[kill process]' | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# ports: what's listening
ports() { lsof -iTCP -sTCP:LISTEN -n -P | awk 'NR==1 || /LISTEN/'; }

# extract: unpack most archive types — `extract foo.tar.gz`
extract() {
  [[ -f "$1" ]] || { echo "extract: '$1' is not a file"; return 1; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x    "$1" ;;
    *) echo "extract: don't know how to unpack '$1'" ;;
  esac
}
