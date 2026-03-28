#!/bin/bash
###############################################################################
# sync_dotfiles.sh — Sync live dotfiles INTO the repo, then commit & push
#
# Usage: ./sync_dotfiles.sh
#
# This pulls your current configs into the repo so you can commit changes.
# To deploy the repo onto a new machine, use install.sh instead.
###############################################################################

set -euo pipefail

# Resolve repo dir relative to this script's location
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Files and dirs to sync from $HOME into the repo
declare -a SYNC_ITEMS=(
    ".bashrc"
    ".tmux.conf"
    ".fzf.bash"
)

# Config dirs to sync (relative to .config/)
declare -a SYNC_CONFIGS=(
    "bash.d"
    ".Conky"
    "alacritty"
    "btop"
    "macchina"
    "neofetch"
    "picom"
    "sxhkd"
    "starship.toml"
    "tmux"
    "wallpapers"
)

echo "Syncing dotfiles into repo at $DOTFILES_DIR ..."

# Sync top-level files
for item in "${SYNC_ITEMS[@]}"; do
    src="$HOME/$item"
    if [[ -e "$src" ]]; then
        rsync -a "$src" "$DOTFILES_DIR/"
    else
        echo "  skip: ~/$item (not found)"
    fi
done

# Sync Scripts directory
if [[ -d "$HOME/Scripts" ]]; then
    rsync -a --delete "$HOME/Scripts/" "$DOTFILES_DIR/Scripts/"
fi

# Sync config dirs
mkdir -p "$DOTFILES_DIR/.config"
for item in "${SYNC_CONFIGS[@]}"; do
    src="$HOME/.config/$item"
    dest="$DOTFILES_DIR/.config/$item"
    if [[ -e "$src" ]]; then
        if [[ -d "$src" ]]; then
            mkdir -p "$dest"
            rsync -a --delete "$src/" "$dest/"
        else
            rsync -a "$src" "$dest"
        fi
    else
        echo "  skip: ~/.config/$item (not found)"
    fi
done

# Commit and push if there are changes
cd "$DOTFILES_DIR"
if git diff --quiet && git diff --staged --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    echo "No changes detected."
    exit 0
fi

git add -A
git commit -m "dotfiles: sync $(date +%Y-%m-%d)"
git push origin main

echo "Done. Dotfiles synced and pushed."
