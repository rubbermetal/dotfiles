###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# trashempty: Empty the trash folder.
trashempty() {
    if command -v trash-empty &>/dev/null; then
        trash-empty
    elif [[ -d "$HOME/.local/share/Trash/files" ]]; then
        rm -rf "$HOME/.local/share/Trash/files/"{..?*,.[!.]*,*} 2>/dev/null
    elif [[ -d "$HOME/.Trash" ]]; then
        rm -rf "$HOME/.Trash/"{..?*,.[!.]*,*} 2>/dev/null
    elif [[ -d "$HOME/.trash" ]]; then
        rm -rf "$HOME/.trash/"{..?*,.[!.]*,*} 2>/dev/null
    fi
}
