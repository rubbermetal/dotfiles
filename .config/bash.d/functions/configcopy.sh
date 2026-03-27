#!/usr/bin/env bash
# configcopy: Copy dotfiles and configuration directories from one user to another.
#
# Usage:
#   source this_script.sh
#   configcopy <from_user> <to_user>
#
# The function copies a predefined set of dotfiles (e.g. .bashrc, .vimrc) and
# selected configuration directories (e.g. .config/fish) from the source user’s
# home directory (or /etc/skel for "default", /root for "root") to the target user’s
# home directory (or /etc/skel or /root, accordingly). It requires root privileges.
#
# Note: The "ask" function must be defined elsewhere.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# configcopy: Copy configuration files from one user to another.
###############################################################################
configcopy() {
    # Validate input parameters.
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: configcopy <from_user> <to_user>"
        return 1
    elif [[ "$1" == "$2" ]]; then
        echo -e "\033[1;31mError:\033[0m 'from_user' and 'to_user' cannot be the same."
        return 2
    fi

    local from_user="$1"
    local to_user="$2"

    # Verify that both users exist, unless they are 'root' or 'default'.
    if ! id "$from_user" &>/dev/null && [[ "$from_user" != "root" && "$from_user" != "default" ]]; then
        echo "Error: Source user '$from_user' does not exist."
        return 1
    fi
    if ! id "$to_user" &>/dev/null && [[ "$to_user" != "root" && "$to_user" != "default" ]]; then
        echo "Error: Target user '$to_user' does not exist."
        return 1
    fi

    # Ensure we have root privileges.
    if (( EUID != 0 )); then
        echo "Please run as root or with sudo."
        return 1
    fi

    local dir_from dir_to owner

    # Resolve source and target directories and determine the owner.
    case "$from_user:$to_user" in
        default:*)
            dir_from="/etc/skel"
            dir_to="/home/$to_user"
            owner="$to_user"
            ;;
        *:default)
            dir_from="/home/$from_user"
            dir_to="/etc/skel"
            owner="root"
            ;;
        root:*)
            dir_from="/root"
            dir_to="/home/$to_user"
            owner="$to_user"
            ;;
        *:root)
            dir_from="/home/$from_user"
            dir_to="/root"
            owner="root"
            ;;
        *)
            dir_from="/home/$from_user"
            dir_to="/home/$to_user"
            owner="$to_user"
            ;;
    esac

    # Normalize paths: ensure trailing slash.
    dir_from="${dir_from%/}/"
    dir_to="${dir_to%/}/"

    # Confirm operation.
    if ! ask "Are you sure you want to copy configuration from ${dir_from} to ${dir_to}?" N; then
        echo "Operation cancelled."
        return 0
    fi

    # Helper function to copy a file or directory.
    copy_item() {
        local src="$1" dst="$2" user="$3"
        if [[ -e "$src" ]]; then
            sudo mkdir -p "$(dirname "$dst")"
            if ! sudo cp -R "$src" "$dst"; then
                echo -e "\033[1;31mError copying ${src}\033[0m"
                return 1
            fi
            if ! sudo chown -R "${user}:${user}" "$dst"; then
                echo -e "\033[1;31mError setting owner for ${dst}\033[0m"
                return 1
            fi
            echo -e "\033[1;32m✔\033[0m Copied: ${src}"
        else
            echo "Skipping ${src} (does not exist)"
        fi
    }

    # Define basic dotfiles to copy.
    local dotfiles=(
        ".bash_logout"
        ".bash_profile"
        ".bashrc"
        ".bashrc_help"
        ".inputrc"
        ".nanorc"
        ".p10k.zsh"
        ".screenrc"
        ".vimrc"
        ".Xauthority"
        ".zshrc"
    )
    local file
    for file in "${dotfiles[@]}"; do
        copy_item "${dir_from}${file}" "${dir_to}${file}" "$owner"
    done

    # Copy additional configuration directories/files.
    copy_item "${dir_from}.config/bashrc" "${dir_to}.config/bashrc" "$owner"
    copy_item "${dir_from}.config/fish"   "${dir_to}.config/fish"   "$owner"
    copy_item "${dir_from}.config/micro"  "${dir_to}.config/micro"  "$owner"

    # Tmux configuration.
    copy_item "${dir_from}.tmux.conf" "${dir_to}.tmux.conf" "$owner"
    if [[ -d "${dir_from}.tmux" ]]; then
        copy_item "${dir_from}.tmux" "${dir_to}.tmux" "$owner"
    fi

    echo -e "Owner set to: \033[1;35m${owner}\033[0m"
    echo -e "\033[1;33mFinished\033[0m copying from \033[1;34m${dir_from%/}\033[0m to \033[1;34m${dir_to%/}\033[0m"
}
