###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mv: verbose and interactive (-vi), with an animated result line.
# Usage:
#   mv report.txt ~/docs/          # normal -v output, then the animation
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
unalias mv 2>/dev/null || true
mv() {
    if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
        anim mv -vi "$@"
    else
        command mv -vi "$@"
    fi
}
