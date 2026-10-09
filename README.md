# dotfiles

A portable macOS dev environment I can stand up on a fresh machine in one command.

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

One script, one setup: the installer installs Homebrew packages, symlinks
configs, sets up zsh, installs runtimes via `mise`, and wires up the AI coding
CLIs. It only prompts for what it must (git identity, default shell).

```sh
./install.sh              # the whole setup
./install.sh --yes        # no prompts, accept all defaults
./install.sh --link-only  # just (re)create the symlinks
./install.sh --doctor     # verify symlinks, tools, mise trust, git identity
```

## Daily commands (Justfile)

With `just` installed (it's in the Brewfile):

```sh
just            # list recipes
just sync       # commit, rebase on origin, push, relink — the everyday command
just sync-check # show what sync would do; changes nothing
just link       # (re)create symlinks
just doctor     # health-check the setup
just update     # git pull + refresh packages + relink
just upgrade    # brew update/upgrade + mise upgrade (everything installed)
just new-mac    # full bootstrap
```

## Syncing between machines

`just sync` is the one command to run before you leave a machine or after you
sit down at another one. In order, it:

1. reports broken symlinks inside the repo (never fatal)
2. stages and commits local edits as `sync: <host> <timestamp>`
3. pulls remote commits with `git pull --rebase --autostash`
4. pushes to `origin`
5. relinks dotfiles (`install.sh --link-only`) and shared agent skills
   (`agents/sync.sh --apply`)

A rebase conflict is never auto-resolved: the rebase is aborted and the repo is
left exactly as it was. Two guards beat a wrong merge, so resolve by hand with
`git pull --rebase`, then `just sync` again.

Useful modifiers: `--check` (dry run), `--no-push` (commit and rebase only),
`--no-link` (git only). If you only changed files on this machine and want the
slow package steps too, run `just update` instead.

## What lives where

```
install.sh              bootstrap (entry point; also --link-only / --doctor)
Justfile                daily commands (just sync / link / doctor / update / upgrade)
bootstrap/lib.sh        shared shell helpers (prompts, logging, symlink)
bootstrap/sync.sh       cross-machine sync (just sync); also --check / --no-push / --no-link
packages/Brewfile       everything: CLI toolbelt, cloud/infra, databases, GUI apps, fonts
zsh/                    curated zsh (oh-my-zsh + powerlevel10k + plugins)
  ├── .zshrc                loader
  ├── exports.zsh           env & PATH
  ├── aliases.zsh           aliases
  └── functions.zsh         shell functions
mise/config.toml        global runtime versions (ruby/node/python/…)
atuin/config.toml       atuin shell history (daemon mode, sync, Ctrl-R)
git/                    portable gitconfig + global gitignore
herdr/config.toml       herdr multiplexer config
aerospace/aerospace.toml  AeroSpace tiling window manager
leader-key/config.json  Leader Key launcher shortcuts
agents/                 shared skills and instructions for Codex, Claude
                        Code, Pi, and OpenCode
ghostty/  nvim/         app configs (symlinked into ~/.config etc.)
```

## Symlinks

`install.sh` links repo files into place, backing up anything real it replaces
(`<file>.bak-<timestamp>`):

| Repo file            | → Target |
|----------------------|----------|
| `ghostty/`           | `~/.config/ghostty` |
| `herdr/config.toml`  | `~/.config/herdr/config.toml` |
| `nvim/`              | `~/.config/nvim` |
| `zsh/.zshrc`         | `~/.zshrc` |
| `git/.gitconfig`     | `~/.gitconfig` |
| `git/.gitignore`     | `~/.gitignore` |
| `mise/config.toml`   | `~/.config/mise/config.toml` |
| `atuin/config.toml`  | `~/.config/atuin/config.toml` |
| `aerospace/aerospace.toml` | `~/.aerospace.toml` |
| `leader-key/config.json`   | `~/Library/Application Support/Leader Key/config.json` |

Shared skills live in [`agents/`](agents/README.md). `just agents-sync` links
each one into all four harnesses. `just agents-setup` also installs tools.
`just agents-check` detects drift. Credentials, OAuth sessions, MCP settings,
proxy state, and CodeGraph indexes stay local.

## Terminal & multiplexer

- **herdr** (the multiplexer) — replaces tmux/zellij. Agent-aware panes, plus
  persistent sessions you can detach and re-attach over SSH (even from a phone).

Ghostty is the terminal window.

## Machine-specific bits (never committed)

Three untracked files hold anything that differs per machine/job:

- **`~/.gitconfig.local`** — your name & email. The installer prompts for these,
  so you never accidentally commit with the wrong identity at a new job.
  Also the place for commit signing (see the comment in `git/.gitconfig`).
- **`~/.zshrc.local`** — work paths, secrets, per-machine overrides. Sourced last.
- **`ghostty/local`** — window geometry & anything monitor-specific. Optional
  (`config-file = ?local`), gitignored, loaded last so it wins.

## AI coding CLIs

Installed by the AI step: **Claude Code** & **Codex** (Homebrew casks) and
**pi** (`pi.dev`, via `npm -g @earendil-works/pi-coding-agent`), plus
**OpenCode** (Homebrew). Shared tools are installed by `agents/setup.sh`.

## Moving to a new machine — checklist

1. `git clone git@github.com:<you>/dotfiles.git ~/dotfiles && cd ~/dotfiles`
   (the first `git` call triggers the Xcode CLT install on a clean Mac)
2. `./install.sh` (it also installs Xcode CLT & Homebrew if missing)
3. Open a new terminal (`exec zsh`)
4. Open `nvim` once so lazy.nvim installs the pinned plugin versions (`lazy-lock.json`)
5. `atuin import zsh` to seed history; `atuin login` to sync it from other machines
   (the e2e key lives in `~/.local/share/atuin/key` — grab it from an old machine
   with `atuin key`)
6. `just doctor` to confirm everything landed

After that, `just sync` is the only command you need day to day: it commits what
you changed on this machine, pulls what the other machine changed, pushes, and
relinks.
