###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# mount: with no arguments, list mounts in aligned columns. With arguments, a normal mount.
# Usage:
#   mount
#   mount /dev/sdb1 /mnt
# zsh expands an alias while it parses a whole block, so the unalias must be its own command.
unalias mount 2>/dev/null || true
mount() {
    if [ "$#" -eq 0 ]; then
        command mount | column -t
    else
        command mount "$@"
    fi
}
