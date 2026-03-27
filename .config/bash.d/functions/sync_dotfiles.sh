###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# Find the dotfiles repo by following the bash.d symlink back to its source
_dotfiles_dir() {
    local bash_d="$HOME/.config/bash.d"
    if [[ -L "$bash_d" ]]; then
        local target
        target="$(readlink "$bash_d")"
        # bash.d -> /path/to/dotfiles/.config/bash.d, strip two levels
        echo "$(cd "$(dirname "$(dirname "$target")")" && pwd)"
    elif [[ -d "$HOME/dotfiles" ]]; then
        echo "$HOME/dotfiles"
    elif [[ -d "$HOME/Projects/dotfiles" ]]; then
        echo "$HOME/Projects/dotfiles"
    else
        echo ""
    fi
}

sync_dotfiles() {
    local dir
    dir="$(_dotfiles_dir)"
    if [[ -z "$dir" || ! -f "$dir/sync_dotfiles.sh" ]]; then
        echo "Error: Cannot locate dotfiles repo." >&2
        return 1
    fi
    "$dir/sync_dotfiles.sh"
}
