###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# up: Move up a given number of directory levels.
up() {
    if [[ -z "$1" || ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Usage: up <number_of_levels>"
        return 1
    fi
    local i
    for (( i = 0; i < "$1"; i++ )); do
        cd .. || return 1
    done
    # Save the current path in MPWD for potential use with 'back'
    export MPWD="$PWD"
}
