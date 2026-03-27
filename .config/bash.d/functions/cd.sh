###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Enhanced 'cd' Function with Fuzzy Jumping Fallback via 'z'
#
# This function behaves like the standard 'cd' but adds:
#   - Defaults to the home directory when no arguments are provided.
#   - Supports multiple arguments for fuzzy directory jumping via 'z'
#     when the target directory is not found.
#   - Graceful fallback if 'z' is not installed.
#   - Upon each successful directory change, it appends the new path to a 
#     cd-history file in the $DATA_DIR directory unique to this terminal,
#     avoiding duplicate entries if the current directory is already logged.
#
# Note: This function is intended for interactive shell sessions.
###############################################################################
cd() {
    local ret=0
    local cd_history_file="$DATA_DIR/cd-history-$$"

    # If not in an interactive shell, use builtin cd directly.
    if [[ $- != *i* ]]; then
        builtin cd "$@"
        ret=$?
    elif [[ "$#" -eq 0 ]]; then
        builtin cd ~
        ret=$?
    elif [[ "$1" == "-" || "$1" == -* ]]; then
        builtin cd "$@"
        ret=$?
    elif [[ -d "$1" ]]; then
        builtin cd "$@"
        ret=$?
    else
        # Fallback: attempt fuzzy jumping using 'z' if installed.
        if command -v z >/dev/null 2>&1; then
            z "$@"
            ret=$?
        else
            echo "cd: no such directory: '$1'" >&2
            ret=1
        fi
    fi

    if [[ $ret -eq 0 ]]; then
        local current_dir
        current_dir=$(pwd)
        # Append only if the last history entry is not the same as current_dir.
        if [[ ! -f "$cd_history_file" || "$(tail -n 1 "$cd_history_file")" != "$current_dir" ]]; then
            echo "$current_dir" >> "$cd_history_file"
        fi
        echo "Directory changed to $current_dir (recorded in cd history: $cd_history_file)."
    else
        echo "cd: failed to change directory." >&2
    fi

    return $ret
}

