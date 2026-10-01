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

# install AI tools, native RTK adapters, and shared settings
agents-setup:
    ./agents/setup.sh

# apply shared settings after pulling this repo; no package upgrades
agents-sync:
    ./agents/sync.sh --apply

# detect drift without changing harness settings
agents-check:
    ./agents/sync.sh --check
