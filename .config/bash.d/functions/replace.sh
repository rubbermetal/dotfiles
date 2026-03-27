# replace.sh
#
# This function uses AWK to replace all occurrences of a specified search
# string with a replacement string in a given file. The search is case
# sensitive by default. To perform a case insensitive search, supply "-case i".
#
# Usage:
#   replace -find "search string" -replace "replacement string" -file "filename" [-case i]
#
# Example:
#   replace -find " is " -replace " ls " -case i -file "log.txt"
#
# Note: The file argument assumes the current working directory if a full path is not provided.

replace() {
    # Initialize local variables with descriptive names.
    local search_pattern=""
    local replacement_text=""
    local target_file=""
    local case_flag="s"  # 's' stands for case sensitive (default), 'i' for insensitive

    # Parse command-line arguments.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -find)
                search_pattern="$2"
                shift 2
                ;;
            -replace)
                replacement_text="$2"
                shift 2
                ;;
            -case)
                # Only accept 'i' (or 'I') for case insensitive; default remains case sensitive.
                if [[ "$2" =~ ^[Ii]$ ]]; then
                    case_flag="i"
                fi
                shift 2
                ;;
            -file)
                target_file="$2"
                shift 2
                ;;
            *)
                echo "Error: Unknown argument: $1" >&2
                return 1
                ;;
        esac
    done

    # Validate required parameters.
    if [[ -z "$search_pattern" ]]; then
        echo "Error: -find argument is required." >&2
        return 1
    fi

    if [[ -z "$replacement_text" ]]; then
        echo "Error: -replace argument is required." >&2
        return 1
    fi

    if [[ -z "$target_file" ]]; then
        echo "Error: -file argument is required." >&2
        return 1
    fi

    # If target_file is not an absolute path, assume current working directory.
    if [[ "$target_file" != /* ]]; then
        target_file="$PWD/$target_file"
    fi

    if [[ ! -f "$target_file" ]]; then
        echo "Error: File not found: $target_file" >&2
        return 1
    fi

    # Create a temporary file for the AWK output.
    local tmp_file
    tmp_file=$(mktemp) || { echo "Error: Could not create temporary file." >&2; return 1; }

    # Use AWK to perform the replacement.
    # If case_flag is set to 'i', set IGNORECASE=1 in AWK.
    if [[ "$case_flag" == "i" ]]; then
        awk -v search="$search_pattern" -v replacement="$replacement_text" 'BEGIN { IGNORECASE = 1 } { gsub(search, replacement) } 1' "$target_file" > "$tmp_file"
    else
        awk -v search="$search_pattern" -v replacement="$replacement_text" '{ gsub(search, replacement) } 1' "$target_file" > "$tmp_file"
    fi

    # Check if AWK was successful and update the original file.
    if mv "$tmp_file" "$target_file"; then
        echo "Replacement complete in $target_file."
    else
        echo "Error: Could not update file: $target_file" >&2
        return 1
    fi
}
