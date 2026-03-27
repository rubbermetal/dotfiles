###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# calc — Evaluate math expressions
#
# Uses python3, bc, or perl (whichever is available).
#
# Usage:
#   calc 2 + 2
#   calc 'sqrt(144)'
#   calc '3.14 * (5**2)'
###############################################################################
calc() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: calc <expression>" >&2
        return 1
    fi

    local expr="$*"

    if command -v python3 &>/dev/null; then
        python3 -c "from math import *; print($expr)"
    elif command -v bc &>/dev/null; then
        echo "$expr" | bc -l
    elif command -v perl &>/dev/null; then
        perl -e "print($expr), print \"\\n\""
    else
        echo "Error: no math tool found (need python3, bc, or perl)" >&2
        return 1
    fi
}
