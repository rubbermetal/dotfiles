###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

roll-dice() {
    local num_dice=$1
    local num_sides=$2

    # Validate input
    if [[ -z $num_dice || -z $num_sides || $num_dice -lt 1 || $num_sides -lt 2 ]]; then
        echo "Usage: roll <number-of-dice> <sides-of-dice>"
        echo "Example: roll 3 6 (Rolls 3 six-sided dice)"
        return 1
    fi

    echo -e "\n--- Rolling $num_dice d${num_sides} ---"
    local total=0
    local results=()

    for ((i = 1; i <= num_dice; i++)); do
        roll=$(( RANDOM % num_sides + 1 ))
        results+=("$roll")
        total=$((total + roll))
    done

    echo "Rolls: ${results[*]}"
    echo "Total: $total"
}

change_hostname() {
    #!/bin/bash

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root. Use sudo."
    exit 1
fi

# Ensure hostname argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 NEW_HOSTNAME"
    exit 1
fi

NEW_HOSTNAME="$1"
CURRENT_HOSTNAME=$(hostname)

# Change hostname using hostnamectl
echo "Changing hostname from '$CURRENT_HOSTNAME' to '$NEW_HOSTNAME'..."
hostnamectl set-hostname "$NEW_HOSTNAME"

# Update /etc/hosts to replace old hostname with new one
if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
    echo "Updated /etc/hosts."
else
    echo "Warning: Old hostname not found in /etc/hosts. You may need to update it manually."
fi

# Confirm change
echo "New hostname: $(hostname)"

# Prompt for reboot
read -p "Reboot now to apply changes? (y/N): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Hostname changed. Reboot to fully apply changes."
fi
}
# repeat: Repeat a command n times.
repeat() {
    if [[ -z "$1" || "$1" -le 0 ]]; then
        echo "Usage: repeat <n> <command>"
        return 1
    fi
    local max="$1"
    shift
    local i
    for (( i=1; i<=max; i++ )); do
        eval "$@"
    done
}
