###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi
###############################################################################
# back: Change to the directory visited N cd's ago.
#
# Usage: back [N]
#   If N is not provided, N defaults to 1.
#
# The function uses a per-shell history file located at:
#   $DATA_DIR/cd-history-$$
# and expects DATA_DIR to be set in your global bashrc.
#
# This version always appends the target directory (i.e. the new current
# directory after the jump) to the cd-history file, even if it might duplicate
# an existing entry.
###############################################################################
back() {
    local back_steps target_dir line_count history_file

    # Default to 1 if no argument is provided, then add 1 to skip the current entry.
    back_steps=$(( ${1:-1} + 1 ))

    history_file="$DATA_DIR/cd-history-$$"
    if [[ ! -f "$history_file" ]]; then
        echo "No cd history file found for this session."
        return 1
    fi

    # Count the number of entries in the history file.
    line_count=$(wc -l < "$history_file")
    if (( line_count < back_steps )); then
        echo "Not enough history to go back $back_steps cd's."
        return 1
    fi

    # Retrieve the target directory: the (back_steps)th line from the bottom.
    target_dir=$(tail -n "$back_steps" "$history_file" | head -n 1)

    # Attempt to change directory using builtin cd.
    if builtin cd "$target_dir"; then
        echo "Changed directory to $target_dir"
        # Append the new current directory to the history file unconditionally.
        echo "$(pwd)" >> "$history_file"
    else
        echo "Failed to change directory to $target_dir" >&2
        return 1
    fi
}

