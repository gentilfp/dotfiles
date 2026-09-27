# Shared AI setup

`agents/` is the source of truth for personal settings across Codex, Pi,
Claude Code, and OpenCode. Clone this dotfiles repository on each machine;
never synchronize whole harness home directories.

## Daily use

```sh
just agents-setup       # install missing tools, sync settings, install RTK adapters
just agents-sync        # apply repo settings; no tool upgrades
just agents-check       # exit nonzero if shared settings have drifted
just agent codex        # optional session through Caveman's local proxy
just agent pi
just agent claude
just agent opencode     # opencode2 is also accepted as a launcher alias
```

The normal `codex`, `pi`, `claude`, and `opencode` commands still work. The
Caveman launcher uses `caveman wrap`, so it adds a proxy for that session.
Existing persistent Caveman integrations are preserved. Their installed paths,
provider routing, databases, and daemon state remain machine-local. Do not run
`caveman enable` again merely to synchronize this repository.

Pass harness arguments directly to the script:

```sh
./agents/run.sh codex --help
```

## What is shared

| Component | Shared source | Integration |
|---|---|---|
| Personal + upstream skills | `skills/` | Individual symlinks into each harness's skill directory |
| Instructions | `AGENTS.md` | Managed block merged into global instructions; existing text retained |
| RTK | `config/rtk.toml` | Native RTK installers for Claude, Codex, Pi, OpenCode |
| Ponytail | `skills/ponytail/`, `config/ponytail.json` | Full-mode skill; no plugin hooks needed |
| Caveman | `skills/caveman/`, `run.sh` | Lite-mode skill plus optional native proxy wrapper |
| Zoku + CodeGraph | `config/mcp.json` | Converted into each harness's native MCP format |

Codex discovers shared skills in `~/.agents/skills`. The other targets are
`~/.claude/skills`, `~/.pi/agent/skills`, and `~/.config/opencode/skills`.
OpenCode and supported tool configs honor `XDG_CONFIG_HOME`.
Pi uses `pi-mcp-adapter`; setup adds it to Pi's package list without replacing
your other packages. Pi installs configured packages when it starts.

Ponytail and Caveman are vendored plain-text skills, pinned in `UPSTREAM.md`.
This provides the portable behavior without duplicate prompt hooks or four
plugin update mechanisms. Native plugin dashboards and lifecycle controls are
not installed. Shared instructions set initial modes; skill instructions honor
explicit per-session changes. The existing `talk-to-me` skill remains available.

RTK hook capabilities depend on the installed RTK/harness versions. Tested
RTK 0.44.2 provides Codex instruction guidance; newer versions may also install
a native rewrite hook. The shared instructions provide an explicit-command
fallback. RTK's upstream installers own their adapters; re-run `agents-setup`
after upgrading RTK. Neither RTK nor this setup changes approval policies.

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

Setup installs missing CodeGraph 1.6.0 and Caveman 1.3.3 via npm; it preserves
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
bash -n install.sh agents/setup.sh agents/sync.sh agents/run.sh
just agents-check
```

The temporary-home acceptance check exercises both MCP layouts, repeated sync,
preserved credentials and approvals, old links, skill backups, concurrent edits,
write-failure rollback, and malformed input. It makes no provider/API calls.

Sources: [RTK](https://github.com/rtk-ai/rtk),
[Ponytail](https://github.com/DietrichGebert/ponytail),
[CodeGraph](https://github.com/colbymchenry/codegraph),
[Caveman](https://github.com/juliusbrussee/caveman),
[Codex MCP](https://developers.openai.com/codex/mcp/).
