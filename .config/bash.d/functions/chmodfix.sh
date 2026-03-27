###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# chmodfix: Recursively fix permissions for code files and directories.
# Caution: This will remove executable permissions on files.
chmodfix() {
    local dir_permissions="0775"  # rwx rwx rx
    local file_permissions="0664" # rw- rw- r--
    local directory="${1:-$PWD}"
    if [[ ! -d "$directory" ]]; then
        echo "Error: Directory '$directory' not found."
        return 1
    fi
    # Protect against modifying system directories.
    case "$directory" in
        "/"|"/root"|"/bin"|"/boot"|"/etc"|"/home"|"/lib"|"/lib64"|"/mnt"|"/opt"|"/proc"|"/sbin"|"/usr/bin"|"/usr/lib"|"/usr/lib64"|"/usr/sbin"|"/srv"|"/usr"|"/var"|"/var/www")
            echo "Error: Cannot change permissions in protected directory '$directory'."
            return 2
            ;;
    esac
    echo "Changing file and directory permissions in:"
    echo "$directory"
    if ask "Are you sure?" N; then
        sudo find "$directory" -type f -exec chmod "$file_permissions" {} \;
        sudo find "$directory" -type d -exec chmod "$dir_permissions" {} \;
        echo "Done."
    fi
}
