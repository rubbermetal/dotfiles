###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# mkalias: Create an alias file in $HOME/.config/bash.d/aliases
# Usage: mkalias alias_name 'actual command'
###############################################################################
mkalias() {
    local alias_name alias_command alias_file alias_dir
    alias_name="$1"
    alias_command="$2"
    alias_dir="$HOME/.config/bash.d/aliases"
    alias_file="$alias_dir/$alias_name.sh"

    # Validate input
    if [[ -z "$alias_name" || -z "$alias_command" ]]; then
        echo "Usage: mkalias alias_name 'command to alias'"
        return 1
    fi

    # Ensure alias directory exists
    mkdir -p "$alias_dir"

    # Write the alias file
    {
        echo "###############################################################################"
        echo "# Prevent Direct Execution"
        echo "###############################################################################"
        echo 'if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then'
        echo '    echo "This script is meant to be sourced, not executed directly."'
        echo '    exit 1'
        echo "fi"
        echo
        echo "alias $alias_name=\"$alias_command\""
    } > "$alias_file"

    # Verify creation
    if [[ -f "$alias_file" ]]; then
        echo "Alias '$alias_name' created successfully at '$alias_file'."
        source $alias_file
    else
        echo "Failed to create alias '$alias_name'."
        return 1
    fi
}

