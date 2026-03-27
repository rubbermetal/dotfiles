###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# Fuzzy directory completion for `cd`, with fallback to bash-completion
_fzf_cd_complete() {
    local curr_word="${COMP_WORDS[COMP_CWORD]}"  # Capture current input
    local dir

    # Check if `fzf` is installed and usable
    if command -v fzf >/dev/null 2>&1; then
        # If no input, use `fzf` to select a directory
        if [[ -z "$curr_word" ]]; then
            dir=$(find . -type d 2>/dev/null | fzf) || return
            COMPREPLY=("$dir")
        else
            # Otherwise, use Bash's built-in directory completion
            COMPREPLY=($(compgen -d -- "$curr_word"))
        fi
    else
        # If `fzf` is missing, use Bash’s default directory completion
        COMPREPLY=($(compgen -d -- "$curr_word"))
    fi
}
# Register the function for `cd` completion
complete -F _fzf_cd_complete cd
