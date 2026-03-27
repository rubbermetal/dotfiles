###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fzcd: Fuzzy find and cd into directories.
###############################################################################
fzcd() {
    local dir
    dir=$(find . -type d | fzf --preview "ls -la {}") || return
    cd "$dir" || return
}
