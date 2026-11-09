###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mx: make executable (calls chmod, so -v and the animation apply).
# Usage:
#   mx run.sh
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias mx 2>/dev/null || true
if command -v chmod >/dev/null 2>&1; then
    # chmod here is the chmod function, so -v --preserve-root and the animation apply
    mx() { chmod a+x "$@"; }
fi
