###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# diagnostic Function
#
# This function checks that:
#   1. The level-2.sh script exists at $HOME/.local/bin/level-2.sh.
#   2. The script is executable.
#   3. (Optional) 'sh' is available to run the script.
#
# If all checks pass, the function executes the level-2.sh script using sh,
# passing along any arguments. Otherwise, it prints an error message and
# returns an appropriate non-zero exit status.
#
# Usage:
#   diagnostic [arguments]
#
# Author: Your Name
# Date: 2025-03-27
###############################################################################
diagnostic() {
    local diag_path="$HOME/.local/bin/level-2"

    # Check if the level-2.sh script exists.
    if [[ ! -f "$diag_path" ]]; then
        echo "Error: level-2 script not found at $diag_path." >&2
        return 127
    fi

    # Check if the level-2.sh script is executable.
    if [[ ! -x "$diag_path" ]]; then
        echo "Error: level-2 script at $diag_path is not executable." >&2
        return 126
    fi

    # Optionally, ensure 'sh' is available (this is usually always present).
    if ! command -v sh >/dev/null 2>&1; then
        echo "Error: 'sh' command is not available." >&2
        return 127
    fi

    # Execute the level-2.sh script using sh, passing any provided arguments.
     "$diag_path" "$@"
    local exit_code=$?
    return "$exit_code"
}

