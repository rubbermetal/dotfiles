# Prevent direct execution; only allow sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed."
    exit 1
fi

# (Optional) Ensure aliases are expanded in this context
shopt -s expand_aliases

# -----------------------------------------------------------------------------
# Function: sync_time
# Description:
#   Syncs the system clock against an atomic NTP server using ntpdate.
# Usage:
#   sync-time   # via the alias below
# -----------------------------------------------------------------------------
sync_time() {
    # Check for ntpdate
    if ! command -v ntpdate &>/dev/null; then
        echo "Error: ntpdate is not installed. Install with:"
        echo "  sudo apt install ntpdate"
        return 1
    fi

    # Show current time
    echo "Current system time: $(date)"

    # Perform the sync
    echo "Syncing time with 0.debian.pool.ntp.org..."
    if sudo ntpdate 0.debian.pool.ntp.org; then
        echo "Time synced successfully."
    else
        echo "Error: Time sync failed."
        return 2
    fi

    # Show updated time
    echo "Updated system time: $(date)"
}

# Expose a hyphenated command name
alias sync-time='sync_time'
