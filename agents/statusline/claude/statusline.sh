#!/usr/bin/env bash
# Minimal Claude Code statusLine: project path, model+effort, 5h/7d usage with reset time.
input=$(cat)

DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty' | sed "s|^$HOME|~|")
[ -z "$DIR" ] && DIR="~"
MODEL=$(echo "$input" | jq -r '.model.display_name // empty')
[ -z "$MODEL" ] && MODEL="loading..."
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')

# Remaining %, not used — rounded to a whole number.
FIVE_HR=$(echo "$input" | jq -r 'if .rate_limits.five_hour.used_percentage then (100 - .rate_limits.five_hour.used_percentage | round) else empty end')
FIVE_HR_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_DAY=$(echo "$input" | jq -r 'if .rate_limits.seven_day.used_percentage then (100 - .rate_limits.seven_day.used_percentage | round) else empty end')
SEVEN_DAY_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

# p = % remaining, so low is bad.
color_for() {
  local p="${1:-0}"
  if (( p < 20 )); then echo "$RED"
  elif (( p < 50 )); then echo "$YELLOW"
  else echo "$GREEN"
  fi
}

until_str() {
  local diff=$(( $1 - $(date +%s) ))
  (( diff < 0 )) && diff=0
  if (( diff >= 86400 )); then
    printf '%dd%dh' $((diff / 86400)) $((diff % 86400 / 3600))
  else
    printf '%dh%02dm' $((diff / 3600)) $((diff % 3600 / 60))
  fi
}

MODEL_LINE="$MODEL"
[ -n "$EFFORT" ] && MODEL_LINE="$MODEL_LINE ($EFFORT)"
echo -e "${DIR} ${DIM}·${RESET} ${MODEL_LINE}"

if [ -n "$FIVE_HR" ]; then
  C=$(color_for "$FIVE_HR")
  USAGE_LINE="5h ${C}${FIVE_HR}%${RESET}"
  [ -n "$FIVE_HR_RESET" ] && USAGE_LINE="$USAGE_LINE ${DIM}(resets $(until_str "$FIVE_HR_RESET"))${RESET}"
else
  USAGE_LINE="5h ${DIM}--%${RESET}"
fi
USAGE_LINE="${USAGE_LINE}  ${DIM}·${RESET}  "
if [ -n "$SEVEN_DAY" ]; then
  C=$(color_for "$SEVEN_DAY")
  USAGE_LINE="${USAGE_LINE}7d ${C}${SEVEN_DAY}%${RESET}"
  [ -n "$SEVEN_DAY_RESET" ] && USAGE_LINE="$USAGE_LINE ${DIM}(resets $(until_str "$SEVEN_DAY_RESET"))${RESET}"
else
  USAGE_LINE="${USAGE_LINE}7d ${DIM}--%${RESET}"
fi
echo -e "$USAGE_LINE"
