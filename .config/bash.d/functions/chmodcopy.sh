#!/usr/bin/env bash
# This script provides a function to copy file permissions from a source
# file to one or more destination files.
#
# Usage:
#   source this_script.sh
#   chmodcopy <source_file> <destination_file>...
#
# This script is intended to be sourced, not executed directly.

###############################################################################
# Prevent Direct Execution
###############################################################################
# This check ensures the script is sourced rather than executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Usage Function
###############################################################################
chmodcopy_usage() {
    echo "Usage: chmodcopy <source_file> <destination_file>..."
    echo "Copies permissions from <source_file> to each <destination_file>."
}

###############################################################################
# chmodcopy: Copy file permissions from a source file to destination file(s)
###############################################################################
chmodcopy() {
    # Check if at least two arguments are provided.
    if [[ "$#" -lt 2 ]]; then
        chmodcopy_usage
        return 1
    fi

    local source_file="$1"
    shift  # Remove source_file from the list of arguments.

    # Check if the source file exists.
    if [[ ! -e "$source_file" ]]; then
        echo "Error: Source file '$source_file' does not exist."
        return 1
    fi

    # Loop over each destination file.
    local dest
    for dest in "$@"; do
        # Check if the destination file exists.
        if [[ ! -e "$dest" ]]; then
            echo "Error: Destination file '$dest' does not exist."
            return 1
        fi

        # Copy permissions from source_file to destination file.
        chmod --reference="$source_file" "$dest"
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to copy permissions from '$source_file' to '$dest'."
            return 1
        fi
    done

    # If everything succeeded, return 0.
    return 0
}



