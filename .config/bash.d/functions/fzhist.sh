###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fzhist: Fuzzy find in command history.
###############################################################################
fzhist() {
    history | fzf --height 40% --reverse --preview "echo {}" | awk '{$1=""; print substr($0,2)}' | xargs -I {} bash -c "{}"
}
