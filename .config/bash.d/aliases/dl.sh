###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# dl: download into ~/Downloads (calls wget, so it resumes with -c and animates).
# Usage:
#   dl https://example.org/file.tgz
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias dl 2>/dev/null || true
if command -v wget >/dev/null 2>&1; then
    # wget here is the wget function above, so -c and the animation apply
    dl() { wget -P "$HOME/Downloads" "$@"; }
fi
