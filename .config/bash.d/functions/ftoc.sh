###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# ftoc: Convert Fahrenheit to Celsius.
# Formula: Celsius = (Fahrenheit - 32) * 5/9
ftoc() {
    # Check for exactly one argument.
    if [ "$#" -ne 1 ]; then
        echo "Usage: ftoc <Fahrenheit>"
        return 1
    fi

    local fahrenheit="$1"

    # Validate that the input is a number.
    if ! [[ "$fahrenheit" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: '$fahrenheit' is not a valid number."
        return 1
    fi

    # Calculate Celsius using bc for floating-point arithmetic.
    local celsius
    celsius=$(echo "scale=4; ($fahrenheit - 32) * 5 / 9" | bc -l)
    echo "$celsius"
}
