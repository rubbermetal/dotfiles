###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# extract: Extract various archive file types.
#
# Usage:
#   extract <archive> [target_directory]
#
# This function supports the following archive types:
#   - .tar.bz2, .tbz2: Uses 'tar xjf'
#   - .tar.gz, .tgz  : Uses 'tar xzf'
#   - .tar.xz       : Uses 'tar xJf'
#   - .tar          : Uses 'tar xf'
#   - .bz2          : Uses 'bunzip2'
#   - .gz           : Uses 'gunzip'
#   - .zip          : Uses 'unzip'
#   - .rar          : Uses 'rar x'
#   - .7z           : Uses '7z x'
#   - .z            : Uses 'uncompress'
#
# The archive filename is converted to lowercase for extension matching,
# allowing uppercase or mixed-case extensions (e.g. ARCHIVE.TGZ).
#
# The function checks that required commands are installed and verifies the
# success of the extraction command. If a target directory is provided, the
# archive is extracted there (if supported by the extraction tool); otherwise,
# the current directory is used.
###############################################################################
extract() {
    local archive="$1"
    local target_dir="${2:-.}"

    # Validate input.
    if [[ -z "$archive" ]]; then
        echo "Usage: extract <archive> [target_directory]"
        return 1
    fi
    if [[ ! -f "$archive" ]]; then
        echo "Error: '$archive' is not a valid file."
        return 1
    fi

    # Convert the archive filename to lowercase for extension matching.
    local alower
    alower="$(echo "$archive" | tr '[:upper:]' '[:lower:]')"

    # Ensure the target directory exists.
    mkdir -p "$target_dir"

    case "$alower" in
        *.tar.bz2|*.tbz2)
            command -v tar &>/dev/null || { echo "Error: 'tar' is not installed."; return 1; }
            if ! tar xjf "$archive" -C "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.tar.gz|*.tgz)
            command -v tar &>/dev/null || { echo "Error: 'tar' is not installed."; return 1; }
            if ! tar xzf "$archive" -C "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.tar.xz)
            command -v tar &>/dev/null || { echo "Error: 'tar' is not installed."; return 1; }
            if ! tar xJf "$archive" -C "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.tar)
            command -v tar &>/dev/null || { echo "Error: 'tar' is not installed."; return 1; }
            if ! tar xf "$archive" -C "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.bz2)
            command -v bunzip2 &>/dev/null || { echo "Error: 'bunzip2' is not installed."; return 1; }
            if ! bunzip2 "$archive"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.gz)
            command -v gunzip &>/dev/null || { echo "Error: 'gunzip' is not installed."; return 1; }
            if ! gunzip "$archive"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.zip)
            command -v unzip &>/dev/null || { echo "Error: 'unzip' is not installed."; return 1; }
            if ! unzip "$archive" -d "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.rar)
            command -v rar &>/dev/null || { echo "Error: 'rar' is not installed."; return 1; }
            if ! rar x "$archive" "$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.7z)
            command -v 7z &>/dev/null || { echo "Error: '7z' is not installed."; return 1; }
            if ! 7z x "$archive" -o"$target_dir"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *.z)
            command -v uncompress &>/dev/null || { echo "Error: 'uncompress' is not installed."; return 1; }
            if ! uncompress "$archive"; then
                echo "Error extracting '$archive'"
                return 1
            fi
            ;;
        *)
            echo "Error: Cannot extract '$archive' - unsupported file extension."
            return 1
            ;;
    esac

    echo "Extracted '$archive' to '$target_dir' successfully."
}
