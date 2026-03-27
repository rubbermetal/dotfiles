###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# chmodcalc: Display symbolic permissions based on octal or symbolic input.
#
# Usage:
#   chmodcalc <octal>
#     e.g., chmodcalc 755
#
#   chmodcalc <owner> <group> <other>
#     e.g., chmodcalc rwx rwx r--
#
# Notes:
#   - For octal input, only 1-3 digits (0–7) are accepted.
#     If fewer than 3 digits are provided (e.g. 77), the input is padded (077).
#   - The function uses ANSI color codes for output.
#   - In the symbolic case, it calculates the octal value then calls itself.
###############################################################################
chmodcalc() {
    # Define color variables.
    local BLUE="\033[0;34m"
    local CYAN="\033[0;36m"
    local GREEN="\033[0;32m"
    local MAGENTA="\033[0;35m"
    local RED="\033[0;31m"
    local YELLOW="\033[0;33m"
    local ERROR="\033[1;31m"
    local NOCOLOR="\033[0m"

    # Helper: Print usage message.
    usage() {
        echo -e "${ERROR}Error: 1 or 3 parameters required.${NOCOLOR}"
        echo "Usage:"
        echo "  chmodcalc <octal>              (e.g., chmodcalc 755)"
        echo "  chmodcalc <owner> <group> <other> (e.g., chmodcalc rwx rwx r--)"
        echo ""
        echo "Notes:"
        echo "  read=4, write=2, execute=1"
    }

    # Case: One argument (assumed octal input).
    if [[ "$#" -eq 1 ]]; then
        local octal="$1"
        # Validate: Must be 1 to 3 digits in 0-7.
        if ! [[ "$octal" =~ ^[0-7]{1,3}$ ]]; then
            echo -e "${RED}Error: Invalid octal input ('$octal'). Must be 1–3 digits (0–7).${NOCOLOR}"
            return 1
        fi

        # Pad to 3 digits if necessary.
        while (( ${#octal} < 3 )); do
            octal="0${octal}"
        done

        # Convert each octal digit to its permission string.
        local part=()
        local i
        for (( i=0; i<3; i++ )); do
            local digit="${octal:i:1}"
            case "$digit" in
                0) part[i]="---" ;;
                1) part[i]="--x" ;;
                2) part[i]="-w-" ;;
                3) part[i]="-wx" ;;
                4) part[i]="r--" ;;
                5) part[i]="r-x" ;;
                6) part[i]="rw-" ;;
                7) part[i]="rwx" ;;
            esac
        done

        # Print the color-coded permissions.
        echo -e "${GREEN}${part[0]}${NOCOLOR} ${YELLOW}${part[1]}${NOCOLOR} ${RED}${part[2]}${NOCOLOR}"
        echo ""

        # Build symbolic examples by stripping '-' characters.
        local ownerSym="${part[0]//-/}"
        local groupSym="${part[1]//-/}"
        local otherSym="${part[2]//-/}"

        echo "Examples:"
        echo -e "${CYAN}chmod -R${NOCOLOR} ${MAGENTA}${octal}${NOCOLOR} ${BLUE}./*${NOCOLOR}"
        echo -e "${CYAN}chmod -R${NOCOLOR} u=${GREEN}${ownerSym}${NOCOLOR},g=${YELLOW}${groupSym}${NOCOLOR},o=${RED}${otherSym}${NOCOLOR} ${BLUE}./*${NOCOLOR}"
        echo ""

    # Case: Three arguments (symbolic input for owner, group, other).
    elif [[ "$#" -eq 3 ]]; then
        local owner="$1" group="$2" other="$3"
        local digits=( 0 0 0 )
        local i=0
        for perm in "$owner" "$group" "$other"; do
            local val=0
            # Validate: Only expected letters should be present.
            if [[ "$perm" =~ [^rwx-] ]]; then
                echo -e "${RED}Error: Invalid symbol in permission string '$perm'. Allowed: r, w, x, or -.${NOCOLOR}"
                return 1
            fi
            [[ "$perm" == *r* ]] && (( val+=4 ))
            [[ "$perm" == *w* ]] && (( val+=2 ))
            [[ "$perm" == *x* ]] && (( val+=1 ))
            digits[i]=$val
            ((i++))
        done
        local octal="${digits[0]}${digits[1]}${digits[2]}"
        # Print the numeric representation and recursively call chmodcalc.
        echo -e "${CYAN}${octal}${NOCOLOR}"
        chmodcalc "$octal"

    else
        usage
        return 1
    fi
}
