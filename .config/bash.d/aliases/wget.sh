###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# wget: resumes partial downloads (-c), with an animated result line and elapsed time.
# Usage:
#   wget https://example.org/file.tgz
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# The animation only runs on a terminal; pipes, scripts and cron get the plain command.
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias wget 2>/dev/null || true
if command -v wget >/dev/null 2>&1; then
    wget() {
        if [ -t 1 ] && [ "${ANIM:-1}" != 0 ] && command -v anim >/dev/null 2>&1; then
            anim wget -c "$@"
        else
            command wget -c "$@"
        fi
    }
fi
