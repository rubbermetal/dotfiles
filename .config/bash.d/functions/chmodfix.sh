###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# chmodfix: Recursively fix permissions for code files and directories.
# Caution: This will remove executable permissions on files.
_chmodfix_run() {
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
    else
        _anim_skip=1
    fi
}

# chmodfix: the work above, then one animated result line.
# Usage:
#   chmodfix ~/web
# Turn the animation off for one command with ANIM=0, or for good with ANIM=0 in your environment.
# _anim_quiet stops the inner mv, cp and mkdir from animating too.
chmodfix() {
    local _rc
    _anim_quiet _chmodfix_run "$@"
    _rc=$?
    _anim_result chmodfix "$_rc" "$@"
    return "$_rc"
}
