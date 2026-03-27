#!/usr/bin/env bash
# This script defines a function, `chmodfiles`, that recursively sets file permissions
# in one or more directories.
#
# Usage:
#   source this_script.sh
#   chmodfiles [-y|--yes] <mode> [directory1 directory2 ...]
#
# <mode>      -> Numeric or symbolic permission mode (e.g. 664 or u=rw,g=r,o=r)
# [directory] -> One or more directories. Defaults to $PWD if none provided.
#
# Examples:
#   chmodfiles 664 /var/www/html
#   chmodfiles --yes 664 /var/www/html /home/user/Documents
#
# Note: This script is intended to be sourced, not executed directly.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# chmodfiles: Recursively set permissions for files in one or more directories.
#
# Options:
#   -y, --yes  Skip the confirmation prompt.
#
# Usage:
#   chmodfiles [-y|--yes] <mode> [directory1 directory2 ...]
###############################################################################
chmodfiles() {
    local confirm=true

    # Process optional flags.
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -y|--yes)
                confirm=false
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: chmodfiles [-y|--yes] <mode> [directory1 directory2 ...]"
                return 1
                ;;
        esac
    done

    local perm="$1"
    shift

    # Check if a permission mode is provided.
    if [[ -z "$perm" ]]; then
        echo "Usage: chmodfiles [-y|--yes] <mode> [directory1 directory2 ...]"
        return 1
    fi

    # Optional: Validate the permission mode using a test on a dummy file.
    local dummy_file="/tmp/chmodfiles_test.$$"
    touch "$dummy_file" 2>/dev/null
    if ! chmod "$perm" "$dummy_file" 2>/dev/null; then
        echo "Error: Invalid mode '$perm' or insufficient privileges."
        rm -f "$dummy_file" 2>/dev/null
        return 1
    fi
    rm -f "$dummy_file" 2>/dev/null

    # If no directories are provided, default to the current directory.
    local directories=()
    if [[ "$#" -eq 0 ]]; then
        directories=("$PWD")
    else
        directories=("$@")
    fi

    local directory
    for directory in "${directories[@]}"; do
        # Verify the directory exists.
        if [[ ! -d "$directory" ]]; then
            echo "Error: Directory '$directory' not found."
            continue
        fi

        # Verify the directory is readable.
        if [[ ! -r "$directory" ]]; then
            echo "Error: Directory '$directory' is not readable."
            continue
        fi

        echo "Changing file permissions to '$perm' in: $directory"

        # Prompt for confirmation if not in quiet mode.
        if "$confirm"; then
            read -r -p "Are you sure you want to change file permissions in '$directory'? [y/N] " response
            case "$response" in
                [yY]|[yY][eE][sS])
                    ;;
                *)
                    echo "Operation cancelled for directory: $directory"
                    continue
                    ;;
            esac
        fi

        # Recursively change permissions for files in the directory.
        if ! find "$directory" -type f -exec chmod "$perm" {} \;; then
            echo "Error: Could not change permissions on some files in '$directory'."
            return 1
        fi
        echo "Done for directory: $directory"
    done
    return 0
}
