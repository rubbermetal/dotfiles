##############################################################>
# Prevent Direct Execution
##############################################################>
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
echo "This script is meant to be sourced, not executed directly."
exit 1
fi

say() {
    # -----------------------------------------------------------------------------
    # say_text - Convert input text to speech using Google TTS and play the audio.
    #
    # Usage:
    #   say_text "Hello, world"
    #   echo "Hello" | say_text
    # -----------------------------------------------------------------------------

    local gtts_cmd="$HOME/venv/bin/gtts-cli"
    local audio_player="mpv"
    local temp_file
    temp_file=$(mktemp --suffix=".mp3")

    # Clean up the temp file on exit
    cleanup() {
        rm -f "$temp_file"
    }
    trap cleanup EXIT

    # Check if gtts-cli exists
    if [[ ! -x "$gtts_cmd" ]]; then
        echo "Error: gtts-cli not found at $gtts_cmd"
        return 1
    fi

    # Check for audio player
    if ! command -v "$audio_player" &>/dev/null; then
        echo "Error: Audio player '$audio_player' not found."
        return 1
    fi

    # Determine the input text
    local text
    if [[ -n "$1" ]]; then
        text="$*"
    elif [[ ! -t 0 ]]; then
        text=$(cat)
    else
        echo "Usage: say_text 'hello world' or echo 'hi' | say_text"
        return 1
    fi

    # Convert text to speech
    "$gtts_cmd" -l en -o "$temp_file" "$text"

    # Play the audio
    "$audio_player" --no-video "$temp_file" &>/dev/null
}
