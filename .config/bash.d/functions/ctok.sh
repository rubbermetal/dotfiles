###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# ctok: Convert Celsius to Kelvin.
# Formula: Kelvin = Celsius + 273.15
ctok() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: ctok <Celsius>"
        return 1
    fi

    local celsius="$1"

    if ! [[ "$celsius" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: '$celsius' is not a valid number."
        return 1
    fi

    local kelvin
    kelvin=$(echo "scale=4; $celsius + 273.15" | bc -l)
    echo "$kelvin"
}
