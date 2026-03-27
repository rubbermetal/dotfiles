###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# display_system_info
#
# Tries to execute the first available system info tool from the list:
#   macchina, neofetch, archey, fastfetch, screenfetch, linuxlogo
#
# For neofetch:
#   - If $CONFIG_BASH_DIR is not set, the default neofetch configuration is used.
#   - If $CONFIG_BASH_DIR/.neofetch.conf exists, it is used with the --config option.
#   - After running neofetch with a custom config, the cursor is moved up one
#     line (using printf '\e[A\e[K') to remove an extra blank line that neofetch
#     typically adds.
#
# If no system-info tool is found, the function prints a warning.
#
# Returns:
#   0 if a tool was found and executed successfully.
#   1 if no tool was found.
###############################################################################
display_system_info() {
    # List of available system-info tools.
    local sysinfo_tools=(
        "macchina"
        "neofetch"
        "archey"
        "fastfetch"
        "screenfetch"
        "linuxlogo"
    )

    for cmd in "${sysinfo_tools[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            if [[ "$cmd" == "neofetch" ]]; then
                if [[ -z "$CONFIG_BASH_DIR" ]]; then
                    # If CONFIG_BASH_DIR is not set, run neofetch with default settings.
                    neofetch
                elif [[ -f "$CONFIG_BASH_DIR/.neofetch.conf" ]]; then
                    # Use the custom neofetch configuration file.
                    neofetch --config "$CONFIG_BASH_DIR/.neofetch.conf"
                    # Remove one blank line that neofetch typically adds.
                    printf '\e[A\e[K'
                else
                    neofetch
                fi
            else
                # Execute the found system-info tool.
                "$cmd"
            fi
            return 0
        fi
    done

    echo "No system info tool (macchina, neofetch, archey, etc.) installed."
    return 1
}
