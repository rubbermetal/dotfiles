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
_trash_run() {
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

# trash: the work above, then one animated result line.
# Usage:
#   trash old.txt
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# _anim_quiet stops the inner mv, cp and mkdir from animating too.
trash() {
    local _rc
    _anim_quiet _trash_run "$@"
    _rc=$?
    _anim_result trash "$_rc" "$@"
    return "$_rc"
}
