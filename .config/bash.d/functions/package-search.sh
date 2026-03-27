###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Package Search Function (Pacman Coloring)
###############################################################################

package-search() {
    if command -v pacman >/dev/null 2>&1; then
        # Arch Linux: Use pacman and detailed color formatting.
        pacman -Ss "$@" | sed -e 's#core/.*#\033[1;31m&\033[0;37m#g' \
                                -e 's#extra/.*#\033[0;32m&\033[0;37m#g' \
                                -e 's#community/.*#\033[1;35m&\033[0;37m#g' \
                                -e 's#^.*/.* [0-9].*#\033[0;36m&\033[0;37m#g'
    elif command -v apt-cache >/dev/null 2>&1; then
        # Debian/Ubuntu: Use apt-cache search and color the entire line green.
        apt-cache search "$@" | sed -e 's/\(.*\)/\033[0;32m\1\033[0m/g'
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora: Use dnf search and color the entire output green.
        dnf search "$@" | sed -e 's/\(.*\)/\033[0;32m\1\033[0m/g'
    elif command -v zypper >/dev/null 2>&1; then
        # openSUSE: Use zypper search and color the entire output green.
        zypper search "$@" | sed -e 's/\(.*\)/\033[0;32m\1\033[0m/g'
    else
        echo "Error: No supported package manager found (pacman, apt-cache, dnf, or zypper)."
        return 1
    fi
}
