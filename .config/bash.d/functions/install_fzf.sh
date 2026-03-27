###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# install_fzf: Uninstalls fzf, then clones and reinstalls it in ~/Projects/fzf
###############################################################################
install_fzf() {
    local fzf_repo="https://github.com/junegunn/fzf.git"
    local fzf_dir="$HOME/Projects/fzf"

    echo "Removing any existing fzf installation..."
    if [[ -d "$fzf_dir" ]]; then
        rm -rf "$fzf_dir"
        echo "Deleted existing fzf directory at $fzf_dir."
    fi

    if command -v fzf &>/dev/null; then
        rm -f "$(command -v fzf)"
        echo "Removed existing fzf binary."
    fi

    echo "Cloning fzf into $fzf_dir..."
    git clone --depth 1 "$fzf_repo" "$fzf_dir"

    echo "Running fzf installation script..."
    "$fzf_dir/install" --all

    echo "Adding fzf to PATH..."
    export PATH="$fzf_dir/bin:$PATH"

    echo "fzf installation complete!"
}
