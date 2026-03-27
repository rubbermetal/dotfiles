###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

if command -v pacman &>/dev/null; then
    # Arch-based
    alias pkgman='sudo pacman'
    alias install='pkgman -S'
    alias uninstall='pkgman -Rcs'
    alias update='pkgman -Syyu --ignore=linux,linux-lts,hplip'
    alias upgrade='pkgman -Syu linux linux-lts'
    alias pkglist='pkgman -Qe'
    alias pkglistmore='pkgman -Q'
    alias pkgsearch='pkgman -Ss'
    alias remove_orphans='pkgman -Qtdq | pkgman -Rns -'
    alias list_orphans='pkgman -Qdt'
    alias convert_deb='debtap'
    alias makepkg='makepkg -srciC'
    alias clearcache='pkgman -Sc'
elif command -v apt &>/dev/null; then
    # Debian/Ubuntu-based
    alias pkgman='sudo apt'
    alias install='pkgman install'
    alias uninstall='pkgman remove'
    alias update='pkgman update'
    alias upgrade='pkgman upgrade'
    alias pkglist='pkgman list --installed'
    alias pkgsearch='pkgman search'
elif command -v dnf &>/dev/null; then
    # Fedora-based
    alias pkgman='sudo dnf'
    alias install='pkgman install'
    alias uninstall='pkgman remove'
    alias update='pkgman check-update'
    alias upgrade='pkgman upgrade'
    alias pkglist='pkgman list installed'
    alias pkgsearch='pkgman search'
elif command -v zypper &>/dev/null; then
    # openSUSE-based
    alias pkgman='sudo zypper'
    alias install='pkgman install'
    alias uninstall='pkgman remove'
    alias update='pkgman refresh'
    alias upgrade='pkgman update'
    alias pkglist='pkgman packages --installed'
    alias pkgsearch='pkgman search'
fi
