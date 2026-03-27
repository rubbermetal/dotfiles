###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fztmux: Fuzzy find and switch to a tmux session.
###############################################################################
fztmux() {
    local session
    session=$(tmux list-sessions -F "#{session_name}" | fzf) || return
    tmux attach-session -t "$session"
}
