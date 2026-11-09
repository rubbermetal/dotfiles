###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mkcd: Create a directory (with parents if needed) and change into it.
_mkcd_run() {
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1" || {
        echo "Error: Could not create or change into directory '$1'."
        return 1
    }
}

# mkcd: the work above, then one animated result line.
# Usage:
#   mkcd new/dir
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# _anim_quiet stops the inner mv, cp and mkdir from animating too.
mkcd() {
    local _rc
    _anim_quiet _mkcd_run "$@"
    _rc=$?
    _anim_result mkcd "$_rc" "$@"
    return "$_rc"
}
