###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Weather and IP Functions
###############################################################################

# weather: Display weather information for a given location.
weather() {
    local location="$1"
    if [[ -z "$location" ]]; then
        echo "Usage: weather <location>"
        return 1
    fi
    if ! command -v elinks &>/dev/null; then
        echo "Error: 'elinks' is required for this function."
        return 1
    fi
    # Fetch weather from Google search results (may break if Google changes its format).
    elinks -dump "http://www.google.com/search?hl=en&q=weather+${location}" \
        | grep -A 5 -m 1 "Weather for" \
        | sed 's;\[26\]Add to iGoogle\[27\]IMG;;g'
}
