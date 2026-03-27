###############################################################################
# cpp.sh
#
# This script defines a function, cpp, that copies a file while displaying a
# progress bar. It first attempts to use rsync with human-readable output. If
# rsync is unavailable, it falls back to using strace with cp to show progress.
#
# Usage:
#   cpp <source> <destination>
#
# Examples:
#   cpp myfile.dat /path/to/destination/        # Copy file into a directory
#   cpp myfile.dat renamed_file.dat             # Copy and rename the file
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
# cpp: Copy a file with a progress bar using rsync or a strace+cp fallback.
#
# Parameters:
#   $1 - Source file to copy.
#   $2 - Destination file or directory.
#
# Returns:
#   0 if the copy operation is successful; 1 otherwise.
###############################################################################
cpp() {
    # Validate that exactly two arguments are provided.
    if [[ "$#" -ne 2 ]]; then
        echo "Usage: cpp <source> <destination>"
        return 1
    fi

    local source_file="$1"
    local dest="$2"

    # Validate that the source file exists and is a regular file.
    if [[ ! -f "$source_file" ]]; then
        echo "Error: Source file '$source_file' does not exist or is not a regular file."
        return 1
    fi

    # If rsync is available, use it for the copy with a progress bar.
    if command -v rsync &>/dev/null; then
        # -a preserves permissions and timestamps.
        # -h displays numbers in human-readable format.
        # --info=progress2 shows a progress bar.
        rsync -ah --info=progress2 "$source_file" "$dest"
        return $?
    else
        # If neither rsync nor strace are available, fall back to plain cp.
        if ! command -v strace &>/dev/null; then
            echo "Warning: Neither 'rsync' nor 'strace' are available. Using plain cp."
            cp "$source_file" "$dest"
            return $?
        fi

        # Determine the file size in bytes using a cross-platform approach.
        local file_size
        if ! file_size=$(stat -c '%s' "$source_file" 2>/dev/null); then
            file_size=$(stat -f '%z' "$source_file" 2>/dev/null)
        fi

        if [[ -z "$file_size" || "$file_size" -eq 0 ]]; then
            echo "Error: Could not determine file size or file is empty."
            cp "$source_file" "$dest"
            return $?
        fi

        # Use strace with cp to track bytes written and display a progress bar.
        # The progress bar updates only when the percentage increases.
        strace -q -ewrite cp -- "$source_file" "$dest" 2>&1 | \
        awk -v total_size="$file_size" '
            BEGIN {
                count = 0;
                last_percent = -1;
            }
            {
                # Assume the last field contains the number of bytes written.
                count += $NF;
                percent = int((count / total_size) * 100);
                if (percent > last_percent) {
                    # Carriage return to update the progress bar on the same line.
                    printf "\r%3d%% [", percent;
                    for (i = 0; i < percent; i++) {
                        printf "=";
                    }
                    printf ">";
                    for (i = percent; i < 100; i++) {
                        printf " ";
                    }
                    printf "]";
                    last_percent = percent;
                }
            }
            END {
                print "\nDone.";
            }'
        return ${PIPESTATUS[0]}
    fi
}

