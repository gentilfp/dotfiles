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

# pull latest, refresh core packages, relink
update:
    git pull --ff-only
    brew bundle --file=packages/Brewfile.core
    ./install.sh --link-only

# regenerate the full machine snapshot (run on a machine you trust as baseline)
dump:
    brew bundle dump --file=packages/Brewfile.full --force

# full interactive bootstrap (fresh machine)
new-mac:
    ./install.sh
