###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# _anim_result: play one result line after a shell function has finished.
# The function does its own work in this shell (cd, prompts), so anim cannot run it.
# Usage (from a wrapper):
#   _anim_result mkcd "$rc" "$@"
# A function sets _anim_skip=1 when the user declined, so nothing is reported.
_anim_result() {
    if [ -n "${_anim_skip:-}" ]; then
        _anim_skip=""
        return 0
    fi
    if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
        anim --result "$@"
    fi
    return 0
}

# _anim_quiet: run a command with the animations off, in this shell (so cd still works).
# A local variable, because zsh keeps ANIM=0 set after `ANIM=0 some_function`.
_anim_quiet() {
    local ANIM=0
    "$@"
}
