# Shared agent setup

`agents/` is the source of truth for personal skills. One Bash script,
`sync.sh`, links every skill in `skills/` into the skill directory of each
harness, so adding a skill is a one-step operation.

## Daily use

```sh
just agents-setup         # install missing tools and sync skills
just agents-sync          # apply skill links; no tool changes
just agents-sync-no-zoku  # same, but skip and unlink the zoku and zok-* skills
just agents-check         # exit nonzero if skill links have drifted
```

## Skills

| | |
|---|---|
| Source | `skills/<name>/SKILL.md` |
| Installed into | `~/.agents/skills` (Codex), `~/.claude/skills` (Claude Code), `~/.pi/agent/skills` (Pi), `${XDG_CONFIG_HOME:-~/.config}/opencode/skills` (OpenCode) |

Claude Code does not read the shared `~/.agents` directory, so its own
directory receives the same links. Every installed skill is a symlink back
into this repository, so harnesses always read the current file.

```sh
./agents/sync.sh                                           # preview
./agents/sync.sh --apply                                   # create and refresh links
./agents/sync.sh --check                                   # exit 1 when links drifted
./agents/sync.sh --apply --exclude zoku --exclude 'zok-*'  # per-machine skill set
```

Behaviour:

- Add a skill: create `skills/<name>/SKILL.md`, run `--apply`.
- Remove or rename one: the next `--apply` unlinks it from every harness.
- Only symlinks that resolve into this repository's `skills/` directory are
  replaced or removed. A real file or directory with a skill's name is an
  error, never an overwrite; unrelated files, directories, and links are left
  alone.
- The script is idempotent and needs no Python, `uv`, or network access.

## Shared instructions

`sync.sh` manages skill links only. `AGENTS.md` holds the instruction block
shared by the global harness instruction files (`~/.codex/AGENTS.md`,
`~/.claude/CLAUDE.md`, `~/.pi/agent/AGENTS.md`,
`~/.config/opencode/AGENTS.md`) and is applied to them by hand on each machine.

## Zoku staged workflow

The original `zoku` skill remains the one-shot, user-approved closure path;
it commits only when explicitly asked. For separate stages, manually invoke
one skill at a time with the same card identifier (for example, `ABC-12`):

```text
plan → implement → test
FAILED → implement → test | BLOCKED → resolve prerequisite → test
PASSED → close
```

1. `zok-plan`: inspect architecture and edge cases; save the plan in the card's prompt. No code or status changes.
2. `zok-implement`: implement the card; save implementation and test instructions in its summary. Leave it in `doing`, uncommitted.
3. `zok-test`: in a fresh session, read the summary, run relevant checks (including end-to-end when needed), and save PASSED, FAILED, or BLOCKED validation.
4. `zok-close`: require a current test pass, commit only intended changes, add the commit hash to the summary, and move the card to `done`. No push.

Failures return to `zok-implement`, then `zok-test` again. Blocked checks do
not permit closure. Each stage stops for your next invocation; there is no
automatic orchestration. The card's prompt and summary carry the handoff
between sessions. Shared rules and a short, card-scoped fingerprint command
live in `skills/zok-plan/zok-common.md`. Test replaces only
the validation block; close adds only closure details. Run `just agents-sync`
to install the new skills locally.

## First machine / another computer

```sh
git clone <your-dotfiles-remote> ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh
```

For an existing machine with the harnesses and Node.js installed:

```sh
git pull --ff-only
just agents-setup
```

For subsequent changes, edit files here, review and commit them, push, then
run `git pull --ff-only && just agents-sync` on the other computer.
`just update` also refreshes Homebrew packages and reapplies the links.
Git is the synchronization mechanism; no background process auto-commits or
overwrites unpushed work. Machine-specific models, projects, permissions,
credentials, and MCP settings stay in their current local files.

Setup installs missing CodeGraph 1.6.0 via npm; it preserves existing
installations. OpenCode comes from Homebrew. These are tested
baselines, not an enforced cross-machine binary lock. Upgrade deliberately and
re-run setup/check. Skill contents are pinned in Git.

## Authentication and projects

Authenticate Zoku separately in each harness after restart:

- Codex: `codex mcp login zoku` (or the desktop MCP settings).
- Claude Code: `/mcp`, select Zoku and authenticate.
- Pi: `/mcp`, select Zoku and authenticate through the adapter.
- OpenCode: `opencode mcp auth zoku`.

Never commit tokens or copy OAuth databases between computers. Configure the
servers in each harness and leave machine-local settings as they are: Zoku is
the HTTP server `https://zoku-app.com/api/mcp`, CodeGraph is the stdio command
`codegraph serve --mcp`.

Run `codegraph init` once inside each code repository you want indexed. Leave
the default daemon enabled so simultaneous harnesses share an index writer.
Do not synchronize `.codegraph/` indexes through Git or a cloud drive.

## Verification

```sh
bash -n agents/sync.sh agents/setup.sh
./agents/test-sync.sh
python3 agents/test_zok.py
./agents/sync.sh --check
just agents-check
```

`test-sync.sh` runs the real script against fixture skills and a throwaway
`HOME`: preview, apply, idempotence, drift, `--exclude`, pruning, relative
links, refusals, the retired typo directory, and option handling. It makes no
network calls and never touches a real harness config.

`--check` is dry: it prints the pending links and exits 1 when a skill is
missing from a harness or a link drifted. It creates nothing.
