###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# trashlist: List the contents of the trash folder.
trashlist() {
    if command -v trash-list &>/dev/null; then
        trash-list
    elif [[ -d "$HOME/.local/share/Trash/files" ]]; then
        ls -la "$HOME/.local/share/Trash/files/"
    elif [[ -d "$HOME/.Trash" ]]; then
        ls -la "$HOME/.Trash/"
    elif [[ -d "$HOME/.trash" ]]; then
        ls -la "$HOME/.trash/"
    else
        echo "No trash folder exists."
    fi
}
