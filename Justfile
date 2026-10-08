# Justfile — daily dotfiles commands. Run `just` to see them.
# Requires `just` (brew install just). https://github.com/casey/just

# list available recipes
default:
    @just --list

# (re)create all symlinks into place
link:
    ./install.sh --link-only

# verify the setup: symlinks, tools, mise trust, git identity
doctor:
    ./install.sh --doctor

# pull latest, refresh packages, relink
update:
    git pull --ff-only
    brew bundle --file=packages/Brewfile
    ./install.sh --link-only

# upgrade everything already installed (formulae + casks + mise runtimes)
upgrade:
    brew update
    brew upgrade
    mise upgrade --bump

# full interactive bootstrap (fresh machine)
new-mac:
    ./install.sh

# install AI tools and shared settings
agents-setup:
    ./agents/setup.sh

# apply shared settings after pulling this repo; no package upgrades
agents-sync:
    ./agents/sync.sh --apply

# apply shared settings, skipping and unlinking Zoku skills (this machine does not use them)
agents-sync-no-zoku:
    ./agents/sync.sh --apply --exclude zoku --exclude 'zok-*'

# detect drift without changing harness settings
agents-check:
    ./agents/sync.sh --check
