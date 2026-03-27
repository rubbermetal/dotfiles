###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mvg: Move a file and change into the destination directory if it exists.
mvg() {
    if [[ "$#" -ne 2 ]]; then
        echo "Usage: mvg <source> <destination>"
        return 1
    fi
    mv "$1" "$2" && [[ -d "$2" ]] && cd "$2"
}
