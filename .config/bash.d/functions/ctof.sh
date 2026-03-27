###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# ctof: Convert Celsius to Fahrenheit.
# Formula: Fahrenheit = (Celsius * 9/5) + 32
ctof() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: ctof <Celsius>"
        return 1
    fi

    local celsius="$1"

    if ! [[ "$celsius" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: '$celsius' is not a valid number."
        return 1
    fi

    local fahrenheit
    fahrenheit=$(echo "scale=4; $celsius * 9 / 5 + 32" | bc -l)
    echo "$fahrenheit"
}
