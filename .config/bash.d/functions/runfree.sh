###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# runfree: Start a program in the background and disown it.
runfree() {
    "$@" > /dev/null 2>&1 & disown
}
