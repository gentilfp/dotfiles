#!/usr/bin/env bash
# Acceptance checks for sync.sh.
#
# Runs a temporary copy of the script against fixture skills and a throwaway
# HOME, so it never reads or writes a real harness config. It makes no network
# or provider calls.
#
# Usage: agents/test-sync.sh
set -uo pipefail

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail=0
ok() { printf 'ok   %s\n' "$*"; }
bad() { printf 'FAIL %s\n' "$*"; fail=1; }
expect() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
unset XDG_CONFIG_HOME
mkdir -p "$HOME"

# Fixture repository: the real script, fixture skills, one non-skill directory.
sync_dir="$HOME/agents"
sync="$sync_dir/sync.sh"
src="$sync_dir/skills"
mkdir -p "$src"
cp "$script_root/sync.sh" "$sync"
chmod +x "$sync"
for name in alpha beta gamma; do
  mkdir -p "$src/$name"
  printf '# %s\n' "$name" >"$src/$name/SKILL.md"
done
mkdir -p "$src/not-a-skill"
printf 'not a skill\n' >"$src/not-a-skill/README.md"

run() { "$sync" "$@"; }

targets=(.agents/skills .claude/skills .pi/agent/skills .config/opencode/skills)

# 1. Preview writes nothing.
run >"$tmp/preview"
expect "preview reports 12 pending links" 'grep -q "12 change(s) pending" "$tmp/preview"'
expect "preview writes nothing" '[[ ! -e "$HOME/.agents" ]]'

# 2. Apply links every skill into every harness.
run --apply >"$tmp/apply"
for target in "${targets[@]}"; do
  expect "links created in $target" \
    '[[ -L "$HOME/'"$target"'/alpha" && -L "$HOME/'"$target"'/beta" && -L "$HOME/'"$target"'/gamma" ]]'
done
expect "non-skill directory ignored" '[[ ! -e "$HOME/.agents/skills/not-a-skill" ]]'

# 3. Idempotence and drift detection.
expect "repeat run is a no-op" 'run | grep -q "already in sync"'
expect "--check passes when in sync" 'run --check >/dev/null'
rm "$HOME/.pi/agent/skills/beta"
expect "--check fails on drift" '! run --check >/dev/null'
run --apply >/dev/null
expect "apply repairs drift" '[[ -L "$HOME/.pi/agent/skills/beta" ]]'

# 4. --exclude unlinks the matched skills and can be reverted.
run --apply --exclude 'gam*' >/dev/null
expect "excluded skill unlinked everywhere" '[[ ! -L "$HOME/.agents/skills/gamma" && ! -L "$HOME/.config/opencode/skills/gamma" ]]'
expect "exclusion counts as drift" '! run --check >/dev/null'
expect "exclusion keeps other skills" '[[ -L "$HOME/.agents/skills/alpha" ]]'
run --apply >/dev/null
expect "unexcluded skill relinked" '[[ -L "$HOME/.agents/skills/gamma" ]]'

# 5. Links this repository owns are pruned; foreign links are not.
ln -s "$src/delta" "$HOME/.claude/skills/delta"
ln -s "../../.agents/skills/orca-cli" "$HOME/.pi/agent/skills/orca-cli"
ln -s "$tmp/elsewhere" "$HOME/.agents/skills/mine"
run --apply >"$tmp/prune"
expect "stale owned link pruned" '[[ ! -L "$HOME/.claude/skills/delta" ]]'
expect "prune is reported" 'grep -q "unlink: $HOME/.claude/skills/delta" "$tmp/prune"'
expect "foreign relative link kept" '[[ -L "$HOME/.pi/agent/skills/orca-cli" ]]'
expect "foreign absolute link kept" '[[ -L "$HOME/.agents/skills/mine" ]]'

# 6. A relative link into this repository resolves as ours and is normalized.
rm "$HOME/.agents/skills/alpha"
ln -s "../../agents/skills/alpha" "$HOME/.agents/skills/alpha"
expect "relative owned link is drift" '! run --check >/dev/null'
run --apply >/dev/null
expect "relative owned link normalized" '[[ "$(readlink "$HOME/.agents/skills/alpha")" == "$src/alpha" ]]'

# 7. Real files and directories are never replaced.
rm "$HOME/.claude/skills/alpha"
mkdir "$HOME/.claude/skills/alpha"
expect "real directory with a skill name fails" '! run --apply 2>/dev/null'
expect "real directory left alone" '[[ -d "$HOME/.claude/skills/alpha" && ! -L "$HOME/.claude/skills/alpha" ]]'
expect "refusal leaves other links alone" '[[ -L "$HOME/.agents/skills/alpha" ]]'
rmdir "$HOME/.claude/skills/alpha"
run --apply >/dev/null
expect "recovers after the directory is removed" 'run --check >/dev/null'

# 8. The retired typo directory is emptied and removed.
mkdir -p "$HOME/.claude/skills,"
ln -s "$src/alpha" "$HOME/.claude/skills,/alpha"
run --apply >/dev/null
expect "legacy links unlinked" '[[ ! -L "$HOME/.claude/skills,/alpha" ]]'
expect "empty legacy directory removed" '[[ ! -d "$HOME/.claude/skills," ]]'
mkdir -p "$HOME/.claude/skills,"
: >"$HOME/.claude/skills,/notes"
run --apply >/dev/null
expect "legacy directory with foreign content kept" '[[ -f "$HOME/.claude/skills,/notes" ]]'

# 9. Option handling.
expect "unknown option rejected" '! run --bogus 2>/dev/null'
expect "--exclude without a value rejected" '! run --exclude 2>/dev/null'
expect "--apply with --check rejected" '! run --apply --check 2>/dev/null'
expect "--help exits zero" 'run --help >/dev/null'

# 10. A repository without skills fails loudly and changes nothing.
mv "$src" "$sync_dir/skills.off"
expect "empty skills directory fails" '! run >/dev/null 2>&1'
expect "failed run changes nothing" '[[ -L "$HOME/.agents/skills/alpha" ]]'
mv "$sync_dir/skills.off" "$src"
expect "recovers once skills return" 'run --check >/dev/null'

printf '\n'
if ((fail)); then
  echo "RESULT: failures"
  exit 1
fi
echo "RESULT: all checks passed"
