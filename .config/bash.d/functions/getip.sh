###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# getip: Retrieve the external (WAN) IP address.
getip() {
    if command -v curl &>/dev/null; then
        curl -s https://ifconfig.me
    elif command -v wget &>/dev/null; then
        wget -qO- https://ifconfig.me
    else
        echo "Error: 'curl' or 'wget' required for this function." >&2
        return 1
    fi
}
