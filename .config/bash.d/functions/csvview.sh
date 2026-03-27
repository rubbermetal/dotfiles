###############################################################################
# csvview.sh
#
# This script defines a function, csvview, that displays a CSV file with its
# columns aligned for easier viewing.
#
# The function first validates the input file. If a CSV-aware tool (like xsv)
# is available, it uses it to properly parse the CSV (handling quoted fields,
# embedded commas, etc.). Otherwise, it falls back to a simpler method using
# the column command.
#
# Usage:
#   csvview <file.csv>
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
# csvview: View a CSV file with columns aligned.
#
# Parameters:
#   $1 - The path to the CSV file.
#
# Returns:
#   0 if the CSV file is displayed successfully; 1 otherwise.
###############################################################################
csvview() {
    local csv_file="$1"

    # Validate input: Check that a file path is provided.
    if [[ -z "$csv_file" ]]; then
        echo "Usage: csvview <file.csv>"
        return 1
    fi

    # Validate that the provided file exists and is a regular file.
    if [[ ! -f "$csv_file" ]]; then
        echo "Error: File '$csv_file' does not exist or is not a regular file."
        return 1
    fi

    # If a CSV-aware tool (e.g., xsv) is installed, use it for better parsing.
    if command -v xsv &>/dev/null; then
        xsv table "$csv_file" | less -S
        return $?
    else
        echo "Warning: 'xsv' is not installed. Falling back to a naive CSV view."
        echo "Note: This method may not handle quoted fields or embedded commas correctly."
        # Use column to align columns; this approach is suitable for simple CSV files.
        column -t -s, "$csv_file" | less -S
        return ${PIPESTATUS[0]}
    fi
}
