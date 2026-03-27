###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# SSH aliases — these rely on hosts defined in ~/.ssh/config
# To set up, add entries like:
#
#   Host arch
#       HostName 172.232.28.180
#       User madhatter
#
# Then: ssh arch (with tab completion, ProxyJump support, etc.)

alias ssh_arch='ssh arch'
