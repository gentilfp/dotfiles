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
./install.sh --full         # the whole machine
./install.sh --link-only    # just (re)create the symlinks
```

## What lives where

```
install.sh              interactive bootstrap (entry point)
bootstrap/lib.sh        shared shell helpers (prompts, logging, symlink)
packages/               tiered Brewfiles
  ├── Brewfile.core         essential CLI — always installed
  ├── Brewfile.casks-core   ghostty, orbstack, claude-code, codex, fonts
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
git/                    portable gitconfig + global gitignore
ghostty/  nvim/         app configs (symlinked into ~/.config etc.)
```

## Symlinks

`install.sh` links repo files into place, backing up anything real it replaces
(`<file>.bak-<timestamp>`):

| Repo file            | → Target |
|----------------------|----------|
| `ghostty/`           | `~/.config/ghostty` |
| `nvim/`              | `~/.config/nvim` |
| `zsh/.zshrc`         | `~/.zshrc` |
| `git/.gitconfig`     | `~/.gitconfig` |
| `git/.gitignore`     | `~/.gitignore` |
| `mise/config.toml`   | `~/.config/mise/config.toml` |

## Machine-specific bits (never committed)

Two untracked files hold anything that differs per machine/job:

- **`~/.gitconfig.local`** — your name & email. The installer prompts for these,
  so you never accidentally commit with the wrong identity at a new job.
- **`~/.zshrc.local`** — work paths, secrets, per-machine overrides. Sourced last.

## AI coding CLIs

Installed by the AI step: **Claude Code** & **Codex** (Homebrew casks) and
**pi** (`pi.dev`, via its curl installer). `gemini-cli` is in `Brewfile.extra`.

## Regenerating the full snapshot

After installing/removing brew stuff on a machine you trust as the baseline:

```sh
brew bundle dump --file=packages/Brewfile.full --force
```

## Moving to a new machine — checklist

1. Install Xcode CLT if prompted: `xcode-select --install`
2. `git clone … ~/dotfiles && cd ~/dotfiles`
3. `./install.sh` → pick **minimal**
4. Open a new terminal (`exec zsh`)
5. Open `nvim` once so lazy.nvim syncs plugins
6. `mise install` to materialize runtimes (the installer does this for you)
