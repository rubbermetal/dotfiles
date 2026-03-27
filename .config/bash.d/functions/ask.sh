#!/usr/bin/env bash
# This script defines an "ask" function that prompts the user for a yes/no answer.
#
# The function ensures robust input validation by:
#   - Normalizing the default answer (if provided) to uppercase.
#   - Trimming any leading/trailing whitespace from the input.
#   - Accepting only a single letter: y or n (case-insensitive).
#   - Limiting the number of attempts to prevent infinite loops.
#
# Usage:
#   ask "Do you want to continue?" "Y"
#   if [[ $? -eq 0 ]]; then
#       echo "User answered yes."
#   else
#       echo "User answered no."
#   fi
#
# To source this function, use:
#   source ask.sh

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# ask: Prompt the user for a yes/no question until a valid answer is given,
#      or until a maximum number of attempts is reached.
#
# Parameters:
#   $1 - The question to ask (e.g., "Install now?").
#   $2 - The default answer ("Y" or "N"). Optional.
#
# Returns:
#   0 if the answer is yes, 1 if the answer is no.
###############################################################################
ask() {
    local question="$1"
    local default_input="${2^^}"  # Normalize default input to uppercase
    local prompt default_choice reply attempts max_attempts

    # Maximum number of attempts before aborting.
    max_attempts=3
    attempts=0

    # Determine prompt and default based on provided default input.
    if [[ "$default_input" == "Y" ]]; then
        prompt="Y/n"
        default_choice="Y"
    elif [[ "$default_input" == "N" ]]; then
        prompt="y/N"
        default_choice="N"
    else
        prompt="y/n"
        default_choice=""
    fi

    while true; do
        ((attempts++))
        if (( attempts > max_attempts )); then
            echo "Too many invalid responses. Aborting." >&2
            return 1
        fi

        # Display the prompt and read input from the terminal.
        echo -n "$question [$prompt] "
        read -r reply </dev/tty

        # Trim all whitespace from the reply.
        reply="${reply//[[:space:]]/}"

        # Use default if the user just pressed ENTER.
        if [[ -z "$reply" ]]; then
            reply="$default_choice"
        fi

        # Validate input: only accept "y" or "n" (case-insensitive).
        case "$reply" in
            [Yy])
                return 0
                ;;
            [Nn])
                return 1
                ;;
            *)
                echo "Invalid input. Please enter 'y' or 'n'." >&2
                ;;
        esac
    done
}

