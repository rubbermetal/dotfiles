###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# Fuzzy file completion for nvim using fzf in Bash
_nvim_fzf_complete() {
    local files
    files=$(find . -type f 2>/dev/null | fzf) || return
    COMPREPLY=("$files")
}
# Bash completion. zsh has no complete builtin.
if command -v complete >/dev/null 2>&1; then
    complete -F _nvim_fzf_complete nvim
fi
