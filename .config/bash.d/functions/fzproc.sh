###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fzproc: Fuzzy find and kill a process.
###############################################################################
fzproc() {
    local pid
    pid=$(ps aux | fzf --preview "echo {}" | awk '{print $2}') || return
    [[ -n "$pid" ]] && kill -9 "$pid" && echo "Killed process $pid"
}
