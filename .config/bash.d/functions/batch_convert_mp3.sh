###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# batch_convert_mp3: Convert all files with a given extension to MP3.
#
# Options:
#   $1: File extension (e.g. wav) [required]
#   $2: Bitrate (optional, default=128k) or --keep flag if bitrate is omitted.
#   $3: Optional --keep flag if not provided as $2.
#
# If conversion succeeds, the original file is removed unless the --keep flag is set.
#
# Usage Examples:
#   batch_convert_mp3 wav            # Convert all .wav files at 128k, prompt before deletion.
#   batch_convert_mp3 wav 192k       # Convert all .wav files at 192k, prompt before deletion.
#   batch_convert_mp3 wav --keep      # Convert and keep originals.
#   batch_convert_mp3 wav 192k --keep  # Convert at 192k and preserve original files.
###############################################################################
batch_convert_mp3() {
    local ext="$1"
    if [[ -z "$ext" ]]; then
        echo "Usage: batch_convert_mp3 <extension> [bitrate] [--keep]"
        return 1
    fi

    # Default values
    local bitrate="128k"
    local keep_original=false

    # Process second and third arguments.
    if [[ -n "${2:-}" ]] && [[ "$2" != "--keep" ]]; then
        bitrate="$2"
    fi
    if [[ "$2" == "--keep" || "$3" == "--keep" ]]; then
        keep_original=true
    fi

    # Check if ffmpeg is installed.
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "Error: ffmpeg is not installed."
        return 1
    fi

    # Enable nullglob so that globs with no match expand to an empty list.
    shopt -s nullglob
    local files=( *."${ext}" )
    if (( ${#files[@]} == 0 )); then
        echo "No files found with extension '${ext}'."
        return 0
    fi

    # Process each file.
    for file in "${files[@]}"; do
        echo -e "Processing file '\e[32m${file}\e[0m'..."

        # Derive the base name and new filename.
        local base="${file%."$ext"}"
        local newfile="${base}.mp3"

        # Run ffmpeg conversion (force overwrite with -y).
        ffmpeg -i "${file}" -vn -ab "$bitrate" -ar 44100 -y "${newfile}"

        if [[ $? -eq 0 && -f "$newfile" ]]; then
            echo -e "[SUCCESS] Converted '${file}' to '\e[32m${newfile}\e[0m'."
            if [[ "$keep_original" != true ]]; then
                # Prompt the user before removing the original file.
                read -r -p "Remove original file '${file}'? [y/N] " reply
                if [[ "$reply" =~ ^[Yy]$ ]]; then
                    rm -f "${file}"
                    echo -e "[REMOVED] Original file '\e[32m${file}\e[0m'."
                else
                    echo "Original file '${file}' preserved."
                fi
            fi
        else
            echo -e "[ERROR] Failed to convert '\e[31m${file}\e[0m'."
        fi
    done
}

