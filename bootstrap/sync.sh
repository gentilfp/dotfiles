#!/usr/bin/env bash
#
#  dotfiles sync — carry this repo between machines without thinking about it.
#
#  Usage:
#    ./bootstrap/sync.sh              commit local edits, rebase on origin, push, relink
#    ./bootstrap/sync.sh --check      report what sync would do; change nothing
#    ./bootstrap/sync.sh --no-push    commit + pull --rebase, stop before pushing
#    ./bootstrap/sync.sh --no-link    git only (skip symlinks and agent skills)
#
#  What it does, in order:
#    1. reports broken symlinks inside the repo (never fatal)
#    2. stages and commits local edits as "sync: <host> <timestamp>"
#    3. pulls remote commits with --rebase --autostash
#    4. pushes, unless --no-push
#    5. relinks dotfiles and shared agent skills, unless --no-link
#
#  Conflicts are never auto-resolved: the rebase is aborted and the repo is left
#  exactly as it was, so you can inspect and resolve by hand.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES="$REPO"
source "$REPO/bootstrap/lib.sh"

CHECK=0
PUSH=1
LINK=1

for arg in "$@"; do
  case "$arg" in
    --check)   CHECK=1 ;;
    --no-push) PUSH=0 ;;
    --no-link) LINK=0 ;;
    -h|--help) sed -n '3,13p' "$0" | sed 's/^#//'; exit 0 ;;
    *) die "unknown argument: $arg" ;;
  esac
done

cd "$REPO"
export ASSUME_YES=1

# ── Repo hygiene ─────────────────────────────────────────────────────────────
# Uses broken_symlinks() from bootstrap/lib.sh. A link that points at nothing
# inside the repo is almost always a mistake; report it, never fix it silently.
report_hygiene() {
  header "Repo hygiene"
  local broken
  broken="$(broken_symlinks)"
  if [[ -z "$broken" ]]; then
    ok "no broken symlinks"
  else
    warn "broken symlink(s) inside the repo:"
    while IFS= read -r l; do
      printf '    %s -> %s\n' "$l" "$(readlink "$l")"
    done <<< "$broken"
    info "remove with: git rm <path>   (or fix the target)"
  fi
}

# ── Git state ────────────────────────────────────────────────────────────────
require_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || die "$REPO is not a git repository"
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  [[ "$branch" == "HEAD" ]] && die "detached HEAD — check out a branch first"
  BRANCH="$branch"
  if ! upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
    die "branch '$BRANCH' has no upstream — run: git push -u origin $BRANCH"
  fi
  UPSTREAM="$upstream"
}

commit_local_edits() {
  header "Local edits"
  local changed
  changed="$(git status --porcelain)"
  if [[ -z "$changed" ]]; then
    ok "working tree clean"
    COMMITTED=0
    return
  fi

  local files
  files="$(printf '%s\n' "$changed" | wc -l | tr -d ' ')"
  step "$files file(s) changed"
  if (( CHECK )); then
    printf '%s\n' "$changed" | sed 's/^/    /'
    info "would commit as \"sync: $(hostname -s) $(date '+%Y-%m-%d %H:%M')\""
    COMMITTED=0
    return
  fi

  git add -A
  if git diff --cached --quiet; then
    ok "nothing new to commit"
    COMMITTED=0
    return
  fi
  git commit --quiet -m "sync: $(hostname -s) $(date '+%Y-%m-%d %H:%M')"
  ok "committed: $(git log -1 --format='%s')"
  COMMITTED=1
}

pull_rebase() {
  header "Pull"
  if (( CHECK )); then
    info "would run: git pull --rebase --autostash $UPSTREAM"
    return
  fi

  step "git fetch origin"
  git fetch --quiet origin

  local incoming
  incoming="$(git rev-list --count "HEAD..$UPSTREAM" 2>/dev/null || echo 0)"
  if [[ "$incoming" == "0" ]]; then
    ok "already up to date with $UPSTREAM"
    return
  fi

  step "$incoming incoming commit(s) — rebasing local work on top"
  if ! git pull --rebase --autostash --quiet "$UPSTREAM"; then
    err "rebase hit a conflict — aborting, nothing was changed"
    git rebase --abort >/dev/null 2>&1 || true
    die "resolve by hand: git pull --rebase  →  fix files  →  git rebase --continue"
  fi
  ok "rebased onto $UPSTREAM"
}

push() {
  header "Push"
  if (( PUSH == 0 )); then
    info "skipped (--no-push); local commits stay here until you push"
    return
  fi
  if (( CHECK )); then
    info "would run: git push origin $BRANCH"
    return
  fi
  if [[ "$(git rev-parse HEAD)" == "$(git rev-parse "$UPSTREAM")" ]]; then
    ok "nothing to push"
    return
  fi
  step "git push origin $BRANCH"
  if ! git push --quiet origin "$BRANCH"; then
    warn "push rejected — another machine pushed first. Run: just sync"
    die "no work was lost; local commits are intact"
  fi
  ok "pushed $BRANCH → origin"
}

relink() {
  header "Relink"
  if (( LINK == 0 )); then
    info "skipped (--no-link)"
    return
  fi
  if (( CHECK )); then
    info "would run: install.sh --link-only and agents/sync.sh --apply"
    return
  fi
  "$REPO/install.sh" --link-only
  "$REPO/agents/sync.sh" --apply
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  header "dotfiles sync"
  info "repo: $REPO"
  if (( CHECK )); then info "check mode — nothing will be written"; fi

  require_repo
  report_hygiene
  commit_local_edits
  pull_rebase
  push
  relink

  echo
  if (( CHECK )); then
    ok "check complete — run 'just sync' to apply"
  else
    ok "synced ✓"
    if (( COMMITTED )); then info "shell changes need: exec zsh"; fi
  fi
}

main
