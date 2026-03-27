###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# SSH aliases — these rely on hosts defined in ~/.ssh/config
# To set up, add entry:
#
#   Host plex
#       HostName 192.168.0.133
#       User pi

alias ssh_plex='ssh plex'
