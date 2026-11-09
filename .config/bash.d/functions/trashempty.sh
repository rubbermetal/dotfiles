###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# trashempty: Empty the trash folder.
_trashempty_run() {
    if command -v trash-empty &>/dev/null; then
        trash-empty
    elif [[ -d "$HOME/.local/share/Trash/files" ]]; then
        find "$HOME/.local/share/Trash/files" -mindepth 1 -delete 2>/dev/null
    elif [[ -d "$HOME/.Trash" ]]; then
        find "$HOME/.Trash" -mindepth 1 -delete 2>/dev/null
    elif [[ -d "$HOME/.trash" ]]; then
        find "$HOME/.trash" -mindepth 1 -delete 2>/dev/null
    fi
}

# trashempty: the work above, then one animated result line.
# Usage:
#   trashempty
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# _anim_quiet stops the inner mv, cp and mkdir from animating too.
trashempty() {
    local _rc
    _anim_quiet _trashempty_run "$@"
    _rc=$?
    _anim_result trashempty "$_rc" "$@"
    return "$_rc"
}
