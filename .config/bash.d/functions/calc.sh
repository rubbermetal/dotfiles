###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# calc Function
#
# This function checks that:
#   1. The calc.pl script exists at $HOME/.local/bin/calc.pl.
#   2. The script is executable.
#   3. Perl is installed and available in your PATH.
#
# If all checks pass, the function runs the calc.pl script using Perl,
# passing along any arguments. Otherwise, it prints a descriptive error
# message and returns an appropriate non-zero exit status.
#
# Usage:
#   calc [arguments]
#
# Author: Your Name
# Date: 2025-03-27
###############################################################################
calc() {
    # Define the full path to the calc.pl script.
    local calc_path="$HOME/.local/bin/calc.pl"

    # Check if the calc.pl script exists.
    if [[ ! -f "$calc_path" ]]; then
        echo "Error: calc.pl script not found at $calc_path." >&2
        return 127
    fi

    # Check if the calc.pl script is executable.
    if [[ ! -x "$calc_path" ]]; then
        echo "Error: calc.pl script at $calc_path is not executable." >&2
        return 126
    fi

    # Ensure that Perl is available.
    if ! command -v perl >/dev/null 2>&1; then
        echo "Error: Perl is not installed or not in your PATH." >&2
        return 127
    fi

    # Execute the calc.pl script using Perl, passing any arguments.
    perl "$calc_path" "$@"
    local exit_code=$?
    return "$exit_code"
}

