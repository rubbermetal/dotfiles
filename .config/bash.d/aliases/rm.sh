###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# rm: asks before bulk deletes and refuses the root (-I --preserve-root), with an animated result line.
# Usage:
#   rm old.log                     # removes it, then the animation
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
unalias rm 2>/dev/null || true
rm() {
    if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
        anim rm -I --preserve-root "$@"
    else
        command rm -I --preserve-root "$@"
    fi
}
