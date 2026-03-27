###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# ftok: Convert Fahrenheit to Kelvin.
# Formula: Kelvin = ((Fahrenheit - 32) * 5/9) + 273.15
ftok() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: ftok <Fahrenheit>"
        return 1
    fi

    local fahrenheit="$1"

    if ! [[ "$fahrenheit" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: '$fahrenheit' is not a valid number."
        return 1
    fi

    local kelvin
    kelvin=$(echo "scale=4; ($fahrenheit - 32) * 5 / 9 + 273.15" | bc -l)
    echo "$kelvin"
}
