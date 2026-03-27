###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# rmalias: Remove an alias file from $HOME/.config/bash.d/aliases and unalias it
# Usage: rmalias alias_name
###############################################################################
rmalias() {
    local alias_name alias_dir alias_file

    alias_name="$1"
    alias_dir="$HOME/.config/bash.d/aliases"
    alias_file="$alias_dir/$alias_name.sh"

    # Validate input
    if [[ -z "$alias_name" ]]; then
        echo "Usage: rmalias alias_name"
        return 1
    fi

    # Check if the alias file exists
    if [[ ! -f "$alias_file" ]]; then
        echo "Alias file for '$alias_name' does not exist at '$alias_file'."
        return 1
    fi

    # Remove the alias file
    if rm "$alias_file"; then
        # Remove the alias from the current shell
        unalias "$alias_name" 2>/dev/null
        echo "Alias '$alias_name' removed successfully."
    else
        echo "Error: Failed to remove alias '$alias_name'."
        return 1
    fi
}

