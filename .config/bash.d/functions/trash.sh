###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Trash Management Functions
###############################################################################

# trash: Move file(s) to the trash folder.
trash() {
    if command -v trash-put &>/dev/null; then
        trash-put "$@"
    elif [[ -d "$HOME/.local/share/Trash/files" ]]; then
        mv "$@" "$HOME/.local/share/Trash/files/"
    elif [[ -d "$HOME/.Trash" ]]; then
        mv "$@" "$HOME/.Trash/"
    elif [[ -d "$HOME/.trash" ]]; then
        mv "$@" "$HOME/.trash/"
    else
        mkdir -p "$HOME/.trash"
        mv "$@" "$HOME/.trash/"
    fi
}
