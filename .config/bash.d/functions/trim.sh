###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# trim: Remove leading and trailing whitespace from a string.
trim() {
    local var="$*"
    # Remove leading whitespace.
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace.
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}
