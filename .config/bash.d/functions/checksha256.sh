###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# checksha256: Verify a file's SHA256 checksum against a provided checksum file.
#
# Usage:
#   checksha256 <downloaded_file> <checksum_file>
#
# The <checksum_file> is expected to contain at least one 64-character hexadecimal string.
# The function outputs a success message if the computed checksum matches the expected one,
# or an error message if they do not match or if an error occurs.
###############################################################################
checksha256() {
    # Argument handling / help.
    if [[ "$#" -lt 2 || "$1" == "--help" || "$1" == "-h" ]]; then
        echo "Usage: checksha256 <downloaded_file> <checksum_file>"
        return 1
    fi

    local downloaded_file="$1"
    local checksum_file="$2"

    # Verify prerequisites.
    if ! command -v sha256sum &>/dev/null; then
        echo "Error: 'sha256sum' is not installed."
        return 1
    fi
    if [[ ! -f "$downloaded_file" ]]; then
        echo "Error: File '$downloaded_file' not found."
        return 1
    fi
    if [[ ! -f "$checksum_file" ]]; then
        echo "Error: Checksum file '$checksum_file' not found."
        return 1
    fi

    # Extract a 64-character hexadecimal string from the checksum file.
    local expected_sum
    expected_sum="$(grep -Eo '\b[a-fA-F0-9]{64}\b' "$checksum_file" | head -n1)"

    # Validate the extracted checksum.
    if [[ -z "$expected_sum" || ${#expected_sum} -ne 64 ]]; then
        echo "Error: Could not parse a valid SHA-256 checksum in '$checksum_file'."
        return 1
    fi

    # Calculate the file's SHA256 checksum.
    local file_sum
    file_sum="$(sha256sum "$downloaded_file" | cut -d' ' -f1)"

    # Define ANSI color codes for output.
    local GREEN="\033[0;32m"
    local RED="\033[0;31m"
    local NOCOLOR="\033[0m"

    # Compare checksums and output the result.
    if [[ "$file_sum" == "$expected_sum" ]]; then
        echo -e "${GREEN}[SUCCESS]${NOCOLOR} Checksums match."
        return 0
    else
        echo -e "${RED}[ERROR]${NOCOLOR} Checksums do not match."
        return 1
    fi
}
