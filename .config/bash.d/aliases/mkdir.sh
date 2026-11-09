###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mkdir: verbose and creates parents (-vp), with an animated result line.
# Usage:
#   mkdir -p projects/new
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias mkdir 2>/dev/null || true
if command -v mkdir >/dev/null 2>&1; then
    mkdir() {
        if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
            anim mkdir -vp "$@"
        else
            command mkdir -vp "$@"
        fi
    }
fi
