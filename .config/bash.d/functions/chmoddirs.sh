#!/usr/bin/env bash
# This script defines a function, `chmoddirs`, that recursively sets permissions
# for directories only. It includes robust error handling, optional confirmation,
# and support for multiple target directories.
#
# Usage:
#   source this_script.sh
#   chmoddirs [-y|--yes] <mode> [directory1 directory2 ...]
#
# Examples:
#   chmoddirs 775 /var/www/html /home/username/Documents
#   chmoddirs --yes u=rwx,g=rx,o=rx
#
# Note: This script is meant to be sourced, not executed directly.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# ask: Prompt the user for confirmation.
#
# Arguments:
#   $1 - The prompt message.
#
# Returns:
#   0 if the user confirms (yes), 1 otherwise.
###############################################################################
ask() {
    local prompt="$1"
    local response
    read -r -p "$prompt [y/N] " response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

###############################################################################
# chmoddirs: Recursively set permissions for directories only.
#
# Usage:
#   chmoddirs [-y|--yes] <mode> [directory1 directory2 ...]
#
# Options:
#   -y, --yes  Skip the confirmation prompt.
#
# Arguments:
#   mode      -> The permission mode (e.g., 775 or u=rwx,g=rx,o=rx).
#   directory -> One or more directories. If none provided, defaults to $PWD.
#
# The function validates the input, confirms the action (unless skipped), and
# applies the mode recursively to directories within each specified target.
###############################################################################
chmoddirs() {
    local confirm=true

    # Process options.
    while [[ "$1" =~ ^- ]]; do
        case "$1" in
            -y|--yes)
                confirm=false
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: chmoddirs [-y|--yes] <mode> [directory1 directory2 ...]"
                return 1
                ;;
        esac
    done

    local perm="$1"
    shift

    # Check if the mode is provided.
    if [[ -z "$perm" ]]; then
        echo "Usage: chmoddirs [-y|--yes] <mode> [directory1 directory2 ...]"
        return 1
    fi

    # Optional: Validate the mode if you expect only numeric permissions.
    # Uncomment the block below if only numeric modes (e.g., 775, 0775) are allowed.
    # if ! [[ "$perm" =~ ^[0-7]{3,4}$ ]]; then
    #     echo "Error: '$perm' is not a valid numeric permission (e.g., 775, 0775)."
    #     return 1
    # fi

    # Determine target directories; default to $PWD if none are provided.
    local directories=()
    if [[ "$#" -eq 0 ]]; then
        directories=("$PWD")
    else
        directories=("$@")
    fi

    local dir
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "Error: Directory '$dir' not found."
            continue
        fi

        echo "Changing directory permissions to '$perm' in: $dir"
        if "$confirm"; then
            if ask "Are you sure you want to change permissions in '$dir'?" ; then
                if ! find "$dir" -type d -exec chmod "$perm" {} \;; then
                    echo "Error: Could not change permissions in '$dir'. Check your privileges."
                    return 1
                fi
                echo "Done for $dir."
            else
                echo "Operation cancelled for $dir."
            fi
        else
            if ! find "$dir" -type d -exec chmod "$perm" {} \;; then
                echo "Error: Could not change permissions in '$dir'. Check your privileges."
                return 1
            fi
            echo "Done for $dir."
        fi
    done
    return 0
}
