#!/bin/bash
# set_psattach_alias.sh
#
# This script checks if the program "reptyr" exists in the user's PATH and is executable.
# If the check passes, it sets the alias "psattach" to "sudo reptyr -T".
# This alias is useful for attaching processes to terminals with elevated permissions.
#
# Usage:
#   source set_psattach_alias.sh
#
# Author: Your Name
# Date: 2025-03-27

set_psattach_alias() {
    # Get the full path of the 'reptyr' executable if it exists.
    local reptyr_path
    reptyr_path=$(command -v reptyr)

    # Check if 'reptyr' exists in the PATH.
    # Missing reptyr is normal. Leave the alias unset and keep startup quiet.
    if [ -z "$reptyr_path" ] || [ ! -x "$reptyr_path" ]; then
        return 0
    fi

    alias psattach='sudo reptyr -T'
}

# Run the function to set the alias.
set_psattach_alias

