###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mkcd: Create a directory (with parents if needed) and change into it.
mkcd() {
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1" || {
        echo "Error: Could not create or change into directory '$1'."
        return 1
    }
}
