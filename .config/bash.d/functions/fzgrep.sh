###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fzgrep: Fuzzy search for text in files.
###############################################################################
fzgrep() {
    local search_term
    search_term=$(echo "" | fzf --prompt "Enter search term: ") || return
    grep -rnI --color=always "$search_term" . | fzf --ansi --preview "bat --style=numbers --color=always --line-range=:100 {1}"
}
