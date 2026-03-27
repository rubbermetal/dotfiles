#!/usr/bin/env bash
# This script defines a "colors24bit" function that tests for 24-bit (true color)
# support by printing a smooth gradient line using ANSI escape codes.
#
# Usage:
#   source this_script.sh
#   colors24bit
#
# The function checks for AWK installation, verifies that stdout is a TTY,
# and provides detailed output instructions.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# colors24bit: Test for 24-bit true color support.
#
# This function prints a gradient line using ANSI escape sequences for 24-bit
# colors. The gradient should be smooth if your terminal supports true color.
#
# Steps:
#   1. Verify that 'awk' is installed.
#   2. Check if stdout is a TTY.
#   3. Explain the test and what to look for.
#   4. Use AWK to generate a 256-column gradient.
###############################################################################
colors24bit() {
    # Check if 'awk' is installed.
    if ! command -v awk &>/dev/null; then
        echo "Error: 'awk' is not installed. Cannot proceed." >&2
        return 1
    fi

    # Check if stdout is a terminal.
    if [[ ! -t 1 ]]; then
        echo "Note: Output is not a terminal (TTY); 24-bit color test may not display properly." >&2
    fi

    # Provide context for the user.
    echo "Testing for 24-bit (true color) support..."
    echo "You should see a smooth color gradient below with no abrupt banding."
    echo "If the gradient appears smooth, your terminal supports 24-bit color."
    echo "If you see banding or incorrect colors, true color may not be supported."
    echo

    # Use AWK to print a 256-column gradient.
    awk 'BEGIN {
        # Create a sample string to cycle through for the gradient display.
        sample = "1234567890"
        # Extend the sample string to ensure we have enough characters.
        for (i = 0; i < 10; i++) sample = sample sample;

        # Loop through 256 columns to generate the gradient.
        for (col = 0; col < 256; col++) {
            # Calculate RGB values for a simple gradient.
            r = 255 - (col * 255 / 255)
            g = (col * 510 / 255)
            b = (col * 255 / 255)
            if (g > 255)
                g = 510 - g

            # Set background to (r, g, b).
            printf "\033[48;2;%d;%d;%dm", r, g, b
            # Set foreground to the inverse of (r, g, b) for contrast.
            printf "\033[38;2;%d;%d;%dm", 255 - r, 255 - g, 255 - b
            # Print a character from the sample string; cycle through it.
            printf "%s\033[0m", substr(sample, (col % length(sample)) + 1, 1)
        }
        # End the line after printing the gradient.
        printf "\n"
    }'
}

