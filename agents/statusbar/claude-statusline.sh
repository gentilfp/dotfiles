#!/usr/bin/env bash
# Claude Code statusLine in the MOSS pill style from zsh/moss-prompt.zsh.
# Reads the statusLine JSON on stdin. Needs jq, a Nerd Font and truecolor.
input=$(cat)

DIR=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
MODEL=$(jq -r '.model.display_name // empty' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // 0' <<<"$input" | cut -d. -f1)
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
DIRTY=$(git -C "$DIR" status --porcelain 2>/dev/null | head -1)

fg() { printf '\033[38;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
bg() { printf '\033[48;2;%d;%d;%dm' "0x${1:0:2}" "0x${1:2:2}" "0x${1:4:2}"; }
R=$'\033[0m' BOLD=$'\033[1m' NOBOLD=$'\033[22m'

SURFACE=161914 RAISED=1F231C
MUTED=70766B FAINT=4B5147 MOSS=7E9273 OCHRE=B69A64 RED=C06B63

# Directory: faint parent path, bold moss anchor (same as the prompt).
case "$DIR" in "$HOME"*) SHOWN="~${DIR#$HOME}" ;; *) SHOWN="$DIR" ;; esac
PARENT="${SHOWN%/*}"; ANCHOR="${SHOWN##*/}"
[ "$PARENT" = "$SHOWN" ] && PARENT="" || PARENT="$PARENT/"

OUT="$(fg $SURFACE)"$''"$R$(bg $SURFACE)$(fg $FAINT)${PARENT}$BOLD$(fg $MOSS)${ANCHOR}$NOBOLD"
if [ -n "$BRANCH" ]; then
  GC=$MOSS; [ -n "$DIRTY" ] && GC=$OCHRE
  OUT+=" $R$(fg $SURFACE)$(bg $RAISED)"$''"$(fg $GC) "$''" ${BRANCH} $R$(fg $RAISED)"$''"$R"
else
  OUT+=" $R$(fg $SURFACE)"$''"$R"
fi

# Right of the pills: quiet text. Context turns ochre past 60 and red past 85.
CC=$MUTED; [ "$PCT" -ge 60 ] && CC=$OCHRE; [ "$PCT" -ge 85 ] && CC=$RED
OUT+="  $(fg $MUTED)${MODEL}  $(fg $CC)ctx ${PCT}%$R"
printf '%s\n' "$OUT"
