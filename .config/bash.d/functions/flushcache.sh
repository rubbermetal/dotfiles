# set_flushcache_alias.sh
#
# This script verifies that all required commands for flushing cache and swap
# exist in the user's PATH and are executable. If everything is in place,
# it defines the alias "flushcache" which will:
#   1. Display current memory usage using "free -h".
#   2. Flush the kernel's cache by echoing "3" into /proc/sys/vm/drop_caches.
#   3. Turn swap off and then back on to clear swap memory.
#   4. Print a highlighted message indicating the operation is complete.
#   5. Display the updated memory usage.
#
# Usage:
#   source set_flushcache_alias.sh
#
# Author: Clay Grace
# Date: 2025-03-27

set_flushcache_alias() {
    # Array of required commands.
    local required_commands=(free swapoff swapon sudo sh)

    # Check each required command.
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" > /dev/null; then
            echo "Error: '$cmd' is not installed or not found in your PATH." >&2
            return 1
        fi
    done

    # Check if the drop_caches file exists. This is necessary for flushing the cache.
    if [ ! -f /proc/sys/vm/drop_caches ]; then
        echo "Error: /proc/sys/vm/drop_caches not found. Are you running on a compatible system?" >&2
        return 1
    fi

    # Define the alias "flushcache" if all checks pass.
    alias flushcache="sudo free -h && sudo sh -c \"echo 3 > /proc/sys/vm/drop_caches\" && sudo swapoff -a && sudo swapon -a && printf '\n\033[1;33m%s\033[0m\n\n' 'Ram-cache and Swap Cleared' && free -h"
    echo "Alias 'flushcache' has been set."
}

# Run the function to set the alias.
set_flushcache_alias


