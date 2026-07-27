# dotfiles

A portable macOS dev environment I can stand up on a fresh machine in one command.

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer is interactive — it asks a few questions, then installs Homebrew
packages, symlinks configs, sets up zsh, installs runtimes via `mise`, and wires
up the AI coding CLIs.

## One-liner

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
```

## Profiles

| Profile     | What you get |
|-------------|--------------|
| **minimal** | Core CLI toolbelt, ghostty, OrbStack (docker), fonts, mise, zsh, AI CLIs. The new-job essentials. |
| **standard**| minimal + cloud/infra tools + local databases. |
| **full**    | Everything from the reference machine (`packages/Brewfile.full`). |
| **custom**  | Pick each group yourself. |

Non-interactive:

```sh
./install.sh --minimal      # essentials, no prompts
./install.sh --standard     # minimal + cloud/infra + databases
./install.sh --full         # the whole machine
./install.sh --link-only    # just (re)create the symlinks
./install.sh --doctor       # verify symlinks, tools, mise trust, git identity
```

## Daily commands (Justfile)

With `just` installed (it's in `Brewfile.core`):

```sh
just            # list recipes
just link       # (re)create symlinks
just doctor     # health-check the setup
just update     # git pull + refresh core packages + relink
just upgrade    # brew update/upgrade + mise upgrade (everything installed)
just dump       # regenerate packages/Brewfile.full from this machine
just new-mac    # full interactive bootstrap
```

## What lives where

```
install.sh              interactive bootstrap (entry point; also --doctor)
Justfile                daily commands (just link / doctor / update / dump)
bootstrap/lib.sh        shared shell helpers (prompts, logging, symlink)
packages/               tiered Brewfiles
  ├── Brewfile.core         essential CLI — always installed
  ├── Brewfile.casks-core   ghostty, cmux, orbstack, claude-code, codex, fonts
  ├── Brewfile.cloud        aws, sops, mkcert, ykman…
  ├── Brewfile.data         postgres, redis, mailhog
  ├── Brewfile.extra        extra CLIs + fun
  ├── Brewfile.casks-extra  the rest of the GUI apps
  └── Brewfile.full         exact snapshot of the reference machine
zsh/                    curated zsh (oh-my-zsh + powerlevel10k + plugins)
  ├── .zshrc                loader
  ├── exports.zsh           env & PATH
  ├── aliases.zsh           aliases
  └── functions.zsh         shell functions
mise/config.toml        global runtime versions (ruby/node/python/…)
atuin/config.toml       atuin shell history (daemon mode, sync, Ctrl-R)
git/                    portable gitconfig + global gitignore
cmux/settings.json      cmux app settings (keybinds; font/theme inherited from ghostty)
herdr/config.toml       herdr multiplexer config
ghostty/  nvim/         app configs (symlinked into ~/.config etc.)
```

## Symlinks

`install.sh` links repo files into place, backing up anything real it replaces
(`<file>.bak-<timestamp>`):

| Repo file            | → Target |
|----------------------|----------|
| `ghostty/`           | `~/.config/ghostty` (cmux reads this too) |
| `cmux/settings.json` | `~/.config/cmux/settings.json` |
| `herdr/config.toml`  | `~/.config/herdr/config.toml` |
| `nvim/`              | `~/.config/nvim` |
| `zsh/.zshrc`         | `~/.zshrc` |
| `git/.gitconfig`     | `~/.gitconfig` |
| `git/.gitignore`     | `~/.gitignore` |
| `mise/config.toml`   | `~/.config/mise/config.toml` |
| `atuin/config.toml`  | `~/.config/atuin/config.toml` |

## Terminal & multiplexer

Two layers, and they stack — one is the window, the other tiles inside it:

- **cmux** (the window) — a native macOS terminal built on *libghostty*, tuned for
  running AI agents in parallel. It reads the terminal **font, colors, and theme
  from `~/.config/ghostty/config`**, so the Dracula theme + JetBrainsMono Nerd
  Font are shared with Ghostty automatically. Only cmux's app-level keybinds live
  in `cmux/settings.json` (split-focus mapped to `opt+shift+hjkl` to match Ghostty).
- **herdr** (the multiplexer) — replaces tmux/zellij. Agent-aware panes, plus
  persistent sessions you can detach and re-attach over SSH (even from a phone).

Ghostty stays installed as a fallback window; `cmux` is the daily driver.

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
**pi** (`pi.dev`, via `npm -g @earendil-works/pi-coding-agent`). `gemini-cli`
is in `Brewfile.extra`.

## Regenerating the full snapshot

After installing/removing brew stuff on a machine you trust as the baseline:

```sh
brew bundle dump --file=packages/Brewfile.full --force
```

## Moving to a new machine — checklist

1. `git clone git@github.com:<you>/dotfiles.git ~/dotfiles && cd ~/dotfiles`
   (the first `git` call triggers the Xcode CLT install on a clean Mac)
2. `./install.sh` → pick **minimal** (it also installs Xcode CLT if missing)
3. Open a new terminal (`exec zsh`)
4. Open `nvim` once so lazy.nvim installs the pinned plugin versions (`lazy-lock.json`)
5. `atuin import zsh` to seed history; `atuin login` to sync it from other machines
   (the e2e key lives in `~/.local/share/atuin/key` — grab it from an old machine
   with `atuin key`)
6. `just doctor` to confirm everything landed
