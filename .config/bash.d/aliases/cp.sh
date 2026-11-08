###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# cp: verbose, interactive, preserving (-vip), with an animated result line.
# Usage:
#   cp report.txt backup/          # normal -v output, then the animation
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
unalias cp 2>/dev/null || true
cp() {
    if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
        anim cp -vip "$@"
    else
        command cp -vip "$@"
    fi
}
