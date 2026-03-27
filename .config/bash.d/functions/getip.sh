###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# getip: Retrieve the external (WAN) IP address.
getip() {
    if ! command -v elinks &>/dev/null; then
        echo "Error: 'elinks' is required for this function."
        return 1
    fi
    elinks -dump "http://checkip.dyndns.org:8245/" \
        | awk '{ print $4 }' \
        | sed '/^$/d; s/^[ ]*//; s/[ ]*$//'
}
