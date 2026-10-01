# Shared AI setup

`agents/` is the source of truth for personal settings across Codex, Pi,
Claude Code, and OpenCode. Clone this dotfiles repository on each machine;
never synchronize whole harness home directories.

## Daily use

```sh
just agents-setup       # install missing tools, sync settings, install RTK adapters
just agents-sync        # apply repo settings; no tool upgrades
just agents-check       # exit nonzero if shared settings have drifted
```

## What is shared

| Component | Shared source | Integration |
|---|---|---|
| Personal skills | `skills/` | Individual symlinks into each harness's skill directory |
| Instructions | `AGENTS.md` | Managed block merged into global instructions; existing text retained |
| RTK | `config/rtk.toml` | Native RTK installers for Claude, Codex, Pi, OpenCode |
| Zoku + CodeGraph | `config/mcp.json` | Converted into each harness's native MCP format |

Codex discovers shared skills in `~/.agents/skills`. The other targets are
`~/.claude/skills`, `~/.pi/agent/skills`, and `~/.config/opencode/skills`.
OpenCode and supported tool configs honor `XDG_CONFIG_HOME`.
Pi uses `pi-mcp-adapter`; setup adds it to Pi's package list without replacing
your other packages. Pi installs configured packages when it starts.

RTK hook capabilities depend on the installed RTK/harness versions. Tested
RTK 0.44.2 provides Codex instruction guidance; newer versions may also install
a native rewrite hook. The shared instructions provide an explicit-command
fallback. RTK's upstream installers own their adapters; re-run `agents-setup`
after upgrading RTK. Neither RTK nor this setup changes approval policies.

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

For an existing machine with the harnesses, Node.js, uv, and RTK installed:

```sh
git pull --ff-only
just agents-setup
```

For subsequent settings changes, edit files here, review and commit them, push,
then run `git pull --ff-only && just agents-sync` on the other computer.
`just update` also refreshes Homebrew packages and reapplies shared settings.
Git is the synchronization mechanism; no background process auto-commits or
overwrites unpushed work. Machine-specific models, projects, permissions,
credentials, and third-party settings stay in their current local files.

Setup installs missing CodeGraph 1.6.0 via npm; it preserves
existing installations. RTK and OpenCode come from Homebrew. These are tested
baselines, not an enforced cross-machine binary lock. Upgrade deliberately and
re-run setup/check. Skill contents and Python parser dependencies are pinned.

## Authentication and projects

Authenticate Zoku separately in each harness after restart:

- Codex: `codex mcp login zoku` (or the desktop MCP settings).
- Claude Code: `/mcp`, select Zoku and authenticate.
- Pi: `/mcp`, select Zoku and authenticate through the adapter.
- OpenCode: `opencode mcp auth zoku`.

Never commit tokens or copy OAuth databases between computers. The canonical
MCP file contains only the public endpoint and the local CodeGraph command.
Existing local headers, auth settings, disabled state, and Codex per-tool
approval policies are preserved. Project-local configs can override globals.

Run `codegraph init` once inside each code repository you want indexed. Leave
the default daemon enabled so simultaneous harnesses share an index writer.
Do not synchronize `.codegraph/` indexes through Git or a cloud drive.

## Preview, recovery, and OpenCode versions

```sh
./agents/sync.sh                  # preview paths only; never prints credentials
./agents/sync.sh --check          # detect drift
./agents/sync.sh --apply          # back up and apply
./agents/sync.sh --opencode-major 2 --apply
```

By default the installed `opencode --version` selects v1 or v2. No automatic
major-version upgrade is performed. V1 uses `mcp.<name>`; v2 uses `mcp.servers`.
The explicit major option is useful when preparing a machine before installing
OpenCode. For v2 migrations with additional legacy MCP servers, first let
OpenCode migrate those entries; sync refuses to leave a mixed schema behind.

All input files are parsed before changes start. Concurrent syncs are locked;
changed target files abort the apply. Writes are atomic per file and failures
roll back completed writes. Close harness settings editors while syncing:
external applications do not participate in the sync lock.

Backups live in `~/.local/state/dotfiles-agents/backups/<timestamp>/`, with a
`manifest.json` mapping numbered backups to original paths. They contain local
config secrets and belong only on this machine. Stop the harness, inspect the
manifest, and copy the required backup back to its listed path to undo a change;
entries marked `absent` had no previous file. Existing real skill directories
are backed up before being replaced with links.

TOML comments are preserved. JSON/JSONC settings are normalized to formatted
JSON only when their values change; original comments remain in the backup.
Two small pinned parsers (`tomlkit`, `json5`) avoid handwritten TOML/JSONC
parsing. `uv` provisions them automatically and needs network access initially.

## Verification

```sh
uv run --with tomlkit==0.13.3 --with json5==0.12.1 python agents/test_sync.py
python3 agents/test_zok.py
bash -n install.sh agents/setup.sh agents/sync.sh
just agents-check
```

The temporary-home acceptance check exercises both MCP layouts, repeated sync,
preserved credentials and approvals, old links, skill backups, concurrent edits,
write-failure rollback, and malformed input. It makes no provider/API calls.

Sources: [RTK](https://github.com/rtk-ai/rtk),
[CodeGraph](https://github.com/colbymchenry/codegraph),
[Codex MCP](https://developers.openai.com/codex/mcp/).
