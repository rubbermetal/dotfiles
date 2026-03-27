#!/bin/bash

# Define source and destination
DOTFILES_DIR=~/Projects/dotfiles

# Sync .config and .bashrc into the dotfiles repo
rsync -av --exclude '.git/' --delete ~/.config "$DOTFILES_DIR/"
rsync -av --delete ~/.bashrc "$DOTFILES_DIR/"
rsync -av --delete ~/Scripts "$DOTFILES_DIR/"
rsync -av --delete ~/.tmux.conf "$DOTFILES_DIR/"
rsync -av --delete ~/.fzf.bash "$DOTFILES_DIR/"


# Change to dotfiles directory
cd "$DOTFILES_DIR" || { echo "Failed to change directory to $DOTFILES_DIR"; exit 1; }

# Check for changes before committing
if git diff --quiet && git diff --staged --quiet; then
    echo "No changes detected. Exiting."
    exit 0
fi

# Commit and push changes
git add .
git commit -m "Updated dotfiles: $(date)"
git push origin main

echo "Dotfiles updated and pushed to GitHub."
