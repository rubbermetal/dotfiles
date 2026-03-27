#!/usr/bin/env bash
###############################################################################
# set_ls_aliases.sh
#
# Enhanced ls alias set with:
#   - eza fallback
#   - tree view via `lt` and `ltree`
#   - icon toggle via $LS_ICONS_MODE (auto|always|none)
#   - `lsinfo` command to show current alias source and config
#
# Usage: source from .bashrc
###############################################################################

set_ls_aliases() {
    # Only define aliases in interactive shells
    if [[ $- != *i* ]]; then
        return
    fi

    # Clean up any previous aliases
    unalias ls ll la l lt ltree ftc lsinfo 2>/dev/null

    # Icon mode toggle (env var): auto | always | none
    local icon_mode="${LS_ICONS_MODE:-always}"

    # Helper to build icon flag
    local icon_flag=""
    case "$icon_mode" in
        always) icon_flag="--icons=always" ;;
        auto)   icon_flag="--icons=auto" ;;
        none)   icon_flag="" ;;
        *)      icon_flag="--icons=always" ;;  # default fallback
    esac

    if command -v eza >/dev/null 2>&1; then
        alias ls="eza $icon_flag --color=always --across --group-directories-first -lhF"
        alias ll="eza $icon_flag -alF --color=always --group-directories-first"
        alias la="eza $icon_flag -A --color=always --group-directories-first"
        alias l="eza $icon_flag --grid --color=always --group-directories-first"
        alias lt="eza $icon_flag --tree --level=2 --group-directories-first"
        alias ltree="eza $icon_flag --tree --group-directories-first"
        alias ftc="eza | rev | cut -d'.' -f1 | rev | sort | uniq -c"

        alias lsinfo='echo -e "\n\e[1;34m[eza active]\e[0m  (icon mode: \e[1m$LS_ICONS_MODE\e[0m)"; alias | grep -E "^\s*alias (ls|ll|la|l|lt|ltree|ftc)="'
    else
        alias ls='ls -lhF --group-directories-first --color=auto'
        alias ll='ls -alF --group-directories-first --color=auto'
        alias la='ls -A --group-directories-first --color=auto'
        alias l='ls -CF --group-directories-first --color=auto'
        alias lt='echo "Error: eza is not installed; tree view not available." >&2'
        alias ltree='echo "Error: eza is not installed; tree view not available." >&2'
        alias ftc='ls | rev | cut -d"." -f1 | rev | sort | uniq -c'

        alias lsinfo='echo -e "\n\e[1;31m[using plain ls]\e[0m"; alias | grep -E "^\s*alias (ls|ll|la|l|lt|ltree|ftc)="'
    fi

    echo "Enhanced ls aliases have been set."
}

# Run now
set_ls_aliases

