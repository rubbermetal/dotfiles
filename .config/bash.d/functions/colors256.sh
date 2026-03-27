#!/usr/bin/env bash
# This script defines the colors256 function, which prints a table of all 256 ANSI colors.
#
# Usage:
#   source this_script.sh
#   colors256
#
# The function displays each color number as both a foreground and background sample.
# It warns the user if stdout is not a TTY (e.g., when redirecting output to a file).

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# colors256: Print a table of all 256 ANSI colors, showing both foreground and background.
#
# This function prints each color number in its respective color. The foreground is
# shown first, followed by the same number as a background color. The colors are
# organized in a grid for easy visual reference.
###############################################################################
colors256() {
    # Check if stdout is a TTY
    if [[ ! -t 1 ]]; then
        echo "Note: stdout is not a TTY. Colors may not display as intended." >&2
    fi

    echo "256-Color Chart: (Showing both foreground and background)"
    echo "Each number is displayed as foreground and as background."
    echo

    local i
    for (( i = 0; i < 256; i++ )); do
        # Print the color as foreground
        printf "\x1b[38;5;%sm%3d\x1b[0m " "$i" "$i"
        # Print the color as background
        printf "\x1b[48;5;%sm%3d\x1b[0m " "$i" "$i"

        # After every 6 pairs, start a new line for better readability
        if ! (( (i + 1) % 6 )); then
            echo
        fi
    done
    echo  # Final newline to reset the terminal line
}

