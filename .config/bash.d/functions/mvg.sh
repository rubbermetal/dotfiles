###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mvg: Move a file and change into the destination directory if it exists.
_mvg_run() {
    if [[ "$#" -ne 2 ]]; then
        echo "Usage: mvg <source> <destination>"
        return 1
    fi
    mv "$1" "$2" || return
    if [[ -d "$2" ]]; then
        cd "$2"
    fi
}

# mvg: the work above, then one animated result line.
# Usage:
#   mvg report.txt ~/docs
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# _anim_quiet stops the inner mv, cp and mkdir from animating too.
mvg() {
    local _rc
    _anim_quiet _mvg_run "$@"
    _rc=$?
    _anim_result mvg "$_rc" "$@"
    return "$_rc"
}
