###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# rmd: remove recursively, forced and verbose (calls rm, so rm's -I and the animation apply).
# Usage:
#   rmd old-project/
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias rmd 2>/dev/null || true
if command -v rm >/dev/null 2>&1; then
    # rm here is the rm function, so -I --preserve-root and the animation apply
    rmd() { rm --recursive --force --verbose "$@"; }
fi
