###############################################################################
# convert_mp3.sh
#
# This script defines a function to convert an audio file to MP3 format using
# ffmpeg. It validates the input, supports custom audio bitrate and sample rate,
# checks for ffmpeg availability, and optionally retains the original file.
#
# Usage (after sourcing this file):
#   convert_mp3 <file> [--keep] [bitrate] [samplerate]
#
# Example:
#   convert_mp3 my_audio.wav --keep 192k 48000
#
# Note:
#   This script is meant to be sourced rather than executed directly.
###############################################################################

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# convert_mp3: Convert an audio file to MP3 format.
#
# This function uses ffmpeg to convert a provided audio file to MP3 format.
# It performs the following checks and operations:
#
#   1. Validates that the input file is provided and exists.
#   2. Checks if ffmpeg is installed.
#   3. Replaces the original file extension with .mp3.
#   4. Supports custom audio bitrate and sample rate (defaults are 128k and 44100).
#   5. Checks ffmpeg's exit code to ensure conversion success.
#   6. Optionally removes the original file unless the --keep flag is provided.
#
# Parameters:
#   $1 - Path to the input audio file.
#   Optional arguments:
#       --keep    : Do not remove the original file after conversion.
#       bitrate   : Audio bitrate for the MP3 (e.g. 128k, default is 128k).
#       samplerate: Audio sample rate for the MP3 (e.g. 44100, default is 44100).
#
# Returns:
#   0 if the conversion is successful; 1 otherwise.
###############################################################################
convert_mp3() {
    local original_file="$1"
    local keep_original=false
    local audio_bitrate="128k"
    local audio_samplerate="44100"

    # Shift past the file name parameter.
    shift

    # Parse optional arguments.
    for arg in "$@"; do
        case "$arg" in
            --keep)
                keep_original=true
                ;;
            *k|*[0-9]k)
                audio_bitrate="$arg"
                ;;
            [0-9]*)
                audio_samplerate="$arg"
                ;;
        esac
    done

    # Validate the input file.
    if [[ -z "$original_file" ]]; then
        echo "Usage: convert_mp3 <file> [--keep] [bitrate] [samplerate]"
        return 1
    fi

    if [[ ! -f "$original_file" ]]; then
        echo "Error: File '$original_file' does not exist."
        return 1
    fi

    # Ensure ffmpeg is installed.
    if ! command -v ffmpeg &>/dev/null; then
        echo "Error: 'ffmpeg' is not installed. Please install ffmpeg to continue."
        return 1
    fi

    # Generate the output filename by stripping any existing extension.
    local base_name="${original_file%.*}"
    local converted_file="${base_name}.mp3"

    # Perform the conversion using ffmpeg.
    if ! ffmpeg -i "$original_file" -vn -ab "$audio_bitrate" -ar "$audio_samplerate" -y "$converted_file"; then
        echo "Error: ffmpeg conversion failed."
        return 1
    fi

    # If conversion succeeded, remove the original file unless --keep is specified.
    if [[ -f "$converted_file" && "$keep_original" == false ]]; then
        rm -f "$original_file"
        echo "Removed original file: '$original_file'"
    fi

    echo "Successfully converted to '$converted_file'"
    return 0
}
