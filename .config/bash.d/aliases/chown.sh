###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# chown: refuses the root (--preserve-root), with an animated result line.
# Usage:
#   chown me:me file
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias chown 2>/dev/null || true
if command -v chown >/dev/null 2>&1; then
    chown() {
        if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
            anim chown --preserve-root "$@"
        else
            command chown --preserve-root "$@"
        fi
    }
fi
