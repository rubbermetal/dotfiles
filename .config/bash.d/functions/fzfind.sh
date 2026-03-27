###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# fzfind: Fuzzy find files with preview using fzf and bat (or cat fallback)
#
# Usage:
#   fzfind [search_directory]
#
# This function searches for files in the specified directory (or current
# directory if none is provided) while excluding certain directories (e.g., .git,
# node_modules). It then allows you to interactively select a file using fzf,
# displaying a preview of the file content using bat (if installed) or cat as a
# fallback.
#
# Dependencies:
#   - fzf: for fuzzy searching.
#   - bat: for file previews (optional; falls back to cat if missing).
###############################################################################
fzfind() {
    # Check for required dependency: fzf.
    if ! command -v fzf &>/dev/null; then
        echo "Error: 'fzf' is not installed or not in PATH."
        return 1
    fi

    # Set the preview command: use 'bat' if available, otherwise fallback to 'cat'.
    local preview_cmd
    if command -v bat &>/dev/null; then
        preview_cmd="bat --style=numbers --color=always --line-range=:100 {}"
    else
        preview_cmd="cat {}"
    fi

    # Use the provided search directory, or default to the current directory.
    local search_dir="${1:-.}"

    # Find files while excluding specific directories.
    local file_list
    file_list=$(find "$search_dir" \
        -path "$search_dir/.git" -prune -o \
        -path "$search_dir/node_modules" -prune -o \
        -type f -print)

    # Check if any files were found.
    if [[ -z "$file_list" ]]; then
        echo "No files found in '$search_dir'."
        return 1
    fi

    # Use fzf to let the user select a file with a preview of its content.
    local selected_file
    selected_file=$(printf '%s\n' "$file_list" | fzf --preview "$preview_cmd") || return

    # Output the selected file.
    echo "Selected: $selected_file"
}
