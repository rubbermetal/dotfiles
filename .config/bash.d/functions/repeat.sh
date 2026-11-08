###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# Bash only. zsh has its own repeat loop (repeat 3 echo hi) and cannot define a function with that name,
# so the loader skips this file there.
# Usage:
#   repeat 3 echo hello      # runs the command 3 times

# repeat: Repeat a command n times.
repeat() {
    if [[ -z "$1" || "$1" -le 0 ]]; then
        echo "Usage: repeat <n> <command>"
        return 1
    fi
    local max="$1"
    shift
    local i
    for (( i=1; i<=max; i++ )); do
        eval "$@"
    done
}
