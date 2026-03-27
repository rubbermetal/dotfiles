#!/usr/bin/env bash
# This script defines a function, 'clone', that safely clones an image file to a target block device.
# It performs several safety checks before running the dd command.
#
# Usage:
#   source this_script.sh
#   clone
#
# Note: This script is intended to be sourced, not executed directly.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# clone: Clone an image file to a block device safely.
#
# This function performs the following steps:
#   1. Verifies that required commands (fzf, dd, lsblk) are installed.
#   2. Prompts for the input image file and checks that it exists and is not a block device.
#   3. Lists available drives using lsblk and lets the user select one via fzf.
#   4. Ensures the selected target drive is not mounted.
#   5. Requires a second confirmation (typing "YES") before proceeding.
#   6. Optionally compares the image file size with the target drive size.
#   7. Uses sudo dd with progress reporting to perform the clone.
#
# Returns:
#   0 if successful, non-zero otherwise.
###############################################################################
clone() {
    # Check for required commands.
    if ! command -v fzf &>/dev/null; then
        echo "Error: fzf is not installed. Please install fzf and try again."
        return 1
    fi

    if ! command -v dd &>/dev/null; then
        echo "Error: dd command not available. Please install it."
        return 1
    fi

    if ! command -v lsblk &>/dev/null; then
        echo "Error: lsblk command not available. This script is intended for Linux systems."
        return 1
    fi

    # Optional: Enforce root privileges.
    # Uncomment the following lines if you want to enforce running as root.
    # if [[ $EUID -ne 0 ]]; then
    #     echo "Please run as root or use sudo."
    #     return 1
    # fi

    # Prompt for the input image file.
    read -rp "Enter the path to the image file (if): " input_file
    if [[ ! -f "$input_file" ]]; then
        echo "Error: File '$input_file' does not exist."
        return 1
    fi

    # Ensure the input file is not a block device.
    if [[ "$input_file" =~ ^/dev/ ]]; then
        echo "Error: '$input_file' appears to be a block device. Please provide an image file, not a device."
        return 1
    fi

    # List available drives using lsblk.
    echo "Select the target drive from the list below."
    echo "WARNING: All data on the selected drive will be erased!"
    local available_drives
    available_drives=$(lsblk -d -n -o NAME,SIZE,MODEL)
    if [[ -z "$available_drives" ]]; then
        echo "No drives found. If you are not using Linux, replace 'lsblk' with an appropriate command."
        return 1
    fi

    # Let the user pick the target drive using fzf.
    local target_line
    target_line=$(echo "$available_drives" | fzf --prompt="Select target drive: ") || {
        echo "Drive selection canceled or fzf failed."
        return 1
    }
    if [[ -z "$target_line" ]]; then
        echo "No drive selected. Aborting."
        return 1
    fi

    # Extract the block device name from the selected line.
    local target_drive
    target_drive=$(awk '{print $1}' <<< "$target_line")
    local target_path="/dev/${target_drive}"

    echo "Selected target drive: ${target_path}"

    # Ensure the target drive is not mounted.
    if mount | grep -q "^${target_path}"; then
        echo "Error: ${target_path} is currently mounted. Unmount it before proceeding."
        return 1
    fi

    # Extra safety: Ask for a second confirmation.
    read -rp "WARNING: This will erase all data on ${target_path}. Type 'YES' to continue: " second_confirm
    if [[ "$second_confirm" != "YES" ]]; then
        echo "Operation aborted."
        return 1
    fi

    # Optional: Compare image file size with target drive size.
    local image_size drive_size
    image_size=$(stat -c%s "$input_file" 2>/dev/null)
    drive_size=$(lsblk -b -n -o SIZE "$target_path" 2>/dev/null | head -n 1)
    if [[ -n "$image_size" && -n "$drive_size" && "$image_size" -gt "$drive_size" ]]; then
        echo "Error: Image file is larger than the target drive."
        return 1
    fi

    # Perform the clone operation using dd with sudo.
    echo "Starting clone operation..."
    if sudo dd if="$input_file" of="$target_path" bs=4M status=progress conv=fsync; then
        echo "Clone completed successfully."
    else
        echo "Error: Clone operation failed."
        return 1
    fi
}
