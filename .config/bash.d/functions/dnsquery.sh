# dnsquery function
#
# This function checks that:
#   1. The dnsquery script exists at $HOME/.local/bin/dnsquery.
#   2. The script is executable.
#   3. Perl is installed and available.
#
# If all checks pass, it calls the script with Perl, passing all arguments.
# Otherwise, it prints a descriptive error message and returns a non-zero status.
#
# To use, source this file in your .bashrc or paste the function definition directly.
#
# Author: Your Name
# Date: 2025-03-27

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi


dnsquery() {
    local dnsquery_path="$HOME/.local/bin/dnsquery"

    # Check if the dnsquery script exists as a file.
    if [[ ! -f "$dnsquery_path" ]]; then
        echo "Error: dnsquery script not found at $dnsquery_path." >&2
        return 127
    fi

    # Check if the dnsquery script is executable.
    if [[ ! -x "$dnsquery_path" ]]; then
        echo "Error: dnsquery script at $dnsquery_path is not executable." >&2
        return 126
    fi

    # Ensure Perl is available in PATH.
    if ! command -v perl >/dev/null 2>&1; then
        echo "Error: Perl is not installed or not in your PATH." >&2
        return 127
    fi

    # Execute the dnsquery script using Perl, passing along any arguments.
    perl "$dnsquery_path" "$@"
    local exit_code=$?
    return "$exit_code"
}

