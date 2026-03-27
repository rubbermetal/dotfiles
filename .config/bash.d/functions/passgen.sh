###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# passgen Function
#
# This function checks that:
#   1. The passgen.pl script exists at $HOME/.local/bin/passgen.pl.
#   2. The script is executable.
#   3. Perl is installed and available in your PATH.
#
# If all checks pass, the function runs the passgen.pl script using Perl,
# passing along any arguments. Otherwise, it prints a descriptive error
# message and returns an appropriate non-zero exit status.
#
# Usage:
#   passgen [arguments]
#
# Author: Your Name
# Date: 2025-03-27
###############################################################################
passgen() {
    local passgen_path="$HOME/.local/bin/passgen.pl"

    # Check if the passgen.pl script exists.
    if [[ ! -f "$passgen_path" ]]; then
        echo "Error: passgen.pl script not found at $passgen_path." >&2
        return 127
    fi

    # Check if the passgen.pl script is executable.
    if [[ ! -x "$passgen_path" ]]; then
        echo "Error: passgen.pl script at $passgen_path is not executable." >&2
        return 126
    fi

    # Ensure that Perl is available in the PATH.
    if ! command -v perl >/dev/null 2>&1; then
        echo "Error: Perl is not installed or not in your PATH." >&2
        return 127
    fi

    # Execute the passgen.pl script using Perl, passing along any arguments.
    perl "$passgen_path" "$@"
    local exit_code=$?
    return "$exit_code"
}

