###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# install_tmux: Installs or updates tmux from source.
# - Clones into ~/Projects/tmux (if not present)
# - Updates repo if already cloned
# - Builds and installs the latest version
###############################################################################
install_tmux() {
    local tmux_repo="https://github.com/tmux/tmux.git"
    local tmux_dir="$HOME/Projects/tmux"
    local install_dir="/usr/local"

    echo "Installing dependencies for tmux..."
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y \
            libevent-dev ncurses-dev build-essential automake bison pkg-config
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y libevent-devel ncurses-devel make automake gcc gcc-c++ kernel-devel bison
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm \
            libevent ncurses base-devel automake bison pkgconf
    else
        echo "Error: Package manager not recognized. Install dependencies manually."
        return 1
    fi

    if [[ -d "$tmux_dir" ]]; then
        echo "Updating existing tmux source in $tmux_dir..."
        cd "$tmux_dir" || return 1
        git pull --rebase
    else
        echo "Cloning tmux into $tmux_dir..."
        git clone --depth 1 "$tmux_repo" "$tmux_dir"
        cd "$tmux_dir" || return 1
    fi

    echo "Building tmux from source..."
    sh autogen.sh
    ./configure --prefix="$install_dir"
    make -j"$(nproc)"

    echo "Installing tmux..."
    sudo make install

    echo "Verifying tmux installation..."
    if command -v tmux &>/dev/null; then
        echo "tmux successfully installed/updated: $(tmux -V)"
    else
        echo "Error: tmux installation failed."
        return 1
    fi
}
