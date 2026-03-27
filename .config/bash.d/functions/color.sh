#!/usr/bin/env bash
# This script defines a "colors" function that prints out a table of basic
# foreground/background color combinations using ANSI escape codes.
#
# Usage:
#   source this_script.sh
#   colors
#
# The function demonstrates ANSI escapes for 30..37 (foreground) and 40..47 (background)
# and shows the effect of adding ;1 (bold). It also checks if stdout is a TTY.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# colors: Print out a table of basic foreground/background color combinations.
#
# Usage:
#   colors
#
# This function demonstrates ANSI escape codes for:
#   - Foreground colors (30..37)
#   - Background colors (40..47)
#   - Bold text (using ;1)
###############################################################################
colors() {
    # Check if stdout is a TTY.
    if [[ ! -t 1 ]]; then
        echo "Warning: Output is not a TTY; color codes may not display properly." >&2
    fi

    # Define escape code variables.
    local ESC=$'\033'
    local RESET="${ESC}[0m"
    local BOLD="${ESC}[1m"

    # Print header information.
    printf "Color escapes: %s\n" '\\e[${value};...;${value}m'
    printf "Values 30..37 are %sforeground colors%s\n" "${ESC}[33m" "${RESET}"
    printf "Values 40..47 are %sbackground colors%s\n" "${ESC}[43m" "${RESET}"
    printf "Value  1 gives a %sbold-faced look%s\n\n" "${BOLD}" "${RESET}"

    # Print header row for background codes.
    printf "         "  # Initial spacing for the first column.
    local bgc
    for bgc in {40..47}; do
        printf "%15s" "bg=$bgc"
    done
    echo
    echo "-------------------------------------------------------------------------------"

    # Loop through foreground codes (30..37).
    local fgc vals
    for fgc in {30..37}; do
        # Print the foreground code label.
        printf "fg=%-2d   " "$fgc"
        # For each background code, print a sample cell.
        for bgc in {40..47}; do
            vals="${fgc};${bgc}"
            # Print a cell with normal and bold text samples.
            printf " %sTEXT%s" "${ESC}[${vals}m" "${RESET}"
            printf " %sBOLD%s" "${ESC}[${vals};1m" "${RESET}"
            printf " |"
        done
        echo    # Newline after each foreground row.
        echo "-------------------------------------------------------------------------------"
    done
}

