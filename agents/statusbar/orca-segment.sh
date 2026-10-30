#!/usr/bin/env bash
# Prints a short Orca orchestration summary for status bars, for example
# "orca 1 running · 2 done". Prints nothing when no worker is active, so the
# status bar stays quiet outside orchestration. Cached for a few seconds because
# status bars redraw often.
cache="${TMPDIR:-/tmp}/orca-segment.$USER"
if [ -f "$cache" ] && [ $(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || stat -c %Y "$cache") )) -lt 5 ]; then
  cat "$cache"; exit 0
fi
out=""
if command -v orca >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  out=$(timeout 3 orca orchestration worker-list --json 2>/dev/null | jq -r '
    [.result.workers[]?.workerState] as $s
    | ($s | map(select(. != "succeeded" and . != "failed" and . != "abandoned" and . != "stopped")) | length) as $run
    | ($s | map(select(. == "succeeded")) | length) as $done
    | ($s | map(select(. == "failed")) | length) as $bad
    | if $run == 0 then empty
      else "orca \($run) running" + (if $done > 0 then " · \($done) done" else "" end) + (if $bad > 0 then " · \($bad) failed" else "" end)
      end' 2>/dev/null)
fi
printf '%s' "$out" >"$cache"
printf '%s' "$out"
