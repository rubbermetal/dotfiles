###############################################################################
# cpg.sh
#
# This script defines a function, cpg, which copies one or more source files
# to a destination and optionally changes the working directory if the
# destination is a directory.
#
# The function performs the following actions:
#   1. Validates that at least two arguments are provided.
#   2. Validates that each source file exists.
#   3. For multiple sources, ensures the destination is an existing directory.
#   4. For a single source, if the destination file exists, prompts the user
#      for confirmation before overwriting.
#   5. Executes the copy command (cp) and checks its exit status.
#   6. If the destination is a directory, attempts to change into it.
#
# Usage:
#   cpg <source1> [source2 ...] <destination>
#
# Examples:
#   cpg file.txt /tmp/backup/           # Copy file.txt into directory /tmp/backup/
#   cpg file1.txt file2.txt /tmp/backup/  # Copy multiple files into /tmp/backup/
#   cpg file.txt renamed_file.txt        # Copy file.txt to renamed_file.txt
#                                        # (with a prompt if renamed_file.txt exists)
#
# Note:
#   This script is meant to be sourced rather than executed directly.
###############################################################################

# Prevent direct execution.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# cpg: Copy one or more files to a destination and change directory if applicable.
#
# Parameters:
#   $1, $2, ..., $n-1  - Source file(s) to be copied.
#   $n                 - Destination (a file or directory).
#
# Returns:
#   0 if the copy operation is successful; 1 otherwise.
###############################################################################
cpg() {
    # Ensure at least two arguments are provided.
    if (( $# < 2 )); then
        echo "Usage: cpg <source1> [source2 ...] <destination>"
        return 1
    fi

    # The destination is the last argument.
    local destination="${!#}"
    # All preceding arguments are considered source files.
    local sources=("${@:1:$#-1}")

    # For multiple sources, the destination must be an existing directory.
    if (( ${#sources[@]} > 1 )); then
        if [[ ! -d "$destination" ]]; then
            echo "Error: When copying multiple files, destination '$destination' must be a directory."
            return 1
        fi
    fi

    # Validate that each source file exists.
    for src in "${sources[@]}"; do
        if [[ ! -e "$src" ]]; then
            echo "Error: Source file '$src' does not exist."
            return 1
        fi
    done

    # If there is a single source file and the destination is not a directory,
    # check for potential overwriting.
    if (( ${#sources[@]} == 1 )) && [[ ! -d "$destination" ]]; then
        if [[ -e "$destination" ]]; then
            read -rp "File '$destination' already exists. Overwrite? (y/N): " user_response
            case "$user_response" in
                [Yy]* ) ;;
                * )
                    echo "Aborted."
                    return 1
                    ;;
            esac
        fi

        # Attempt to copy the single source file to the destination.
        if ! cp "${sources[0]}" "$destination"; then
            echo "Error: Failed to copy '${sources[0]}' to '$destination'."
            return 1
        fi
        echo "Copied '${sources[0]}' to '$destination'."
    else
        # For multiple sources or if the destination is a directory.
        if ! cp "${sources[@]}" "$destination"; then
            echo "Error: Failed to copy files to '$destination'."
            return 1
        fi
        echo "Copied ${#sources[@]} file(s) to directory '$destination'."
    fi

    # If the destination is a directory, attempt to change into it.
    if [[ -d "$destination" ]]; then
        if cd "$destination"; then
            echo "Changed directory to '$destination'."
        else
            echo "Warning: Copied files but failed to change directory to '$destination'."
        fi
    fi

    return 0
}

