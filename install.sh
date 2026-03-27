#!/bin/bash
###############################################################################
# install.sh — Deploy dotfiles onto a new (or existing) machine
#
# Usage: ./install.sh [--force]
#
# Creates symlinks from $HOME to the repo. Existing files are backed up
# to ~/.dotfiles_backup/<timestamp>/ unless --force is passed.
#
# Works on: Debian, Ubuntu, Raspberry Pi OS, Arch, Fedora, macOS
###############################################################################

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
FORCE=false

[[ "${1:-}" == "--force" ]] && FORCE=true

# --- OS / distro detection ---
detect_os() {
    case "$(uname -s)" in
        Linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                echo "${ID:-linux}"
            else
                echo "linux"
            fi
            ;;
        Darwin) echo "macos" ;;
        *)      echo "unknown" ;;
    esac
}

OS="$(detect_os)"
echo "Detected OS: $OS"

# --- Helper: symlink with backup ---
link_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        return
    fi

    # Already linked correctly
    if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
        return
    fi

    # Backup existing file/dir
    if [[ -e "$dest" || -L "$dest" ]]; then
        if $FORCE; then
            rm -rf "$dest"
        else
            mkdir -p "$BACKUP_DIR"
            echo "  backup: $dest -> $BACKUP_DIR/"
            mv "$dest" "$BACKUP_DIR/"
        fi
    fi

    # Ensure parent dir exists
    mkdir -p "$(dirname "$dest")"

    ln -sf "$src" "$dest"
    echo "  linked: $dest -> $src"
}

echo ""
echo "Installing dotfiles from $DOTFILES_DIR ..."
echo ""

# --- Top-level dotfiles ---
link_file "$DOTFILES_DIR/.bashrc"    "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.fzf.bash"  "$HOME/.fzf.bash"

# --- .config directories ---
CONFIG_DIRS=(
    "bash.d"
    ".Conky"
    "alacritty"
    "btop"
    "conky"
    "macchina"
    "neofetch"
    "picom"
    "sxhkd"
    "tmux"
    "wallpapers"
)

for dir in "${CONFIG_DIRS[@]}"; do
    link_file "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
done

# --- .config single files ---
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# --- Scripts ---
link_file "$DOTFILES_DIR/Scripts" "$HOME/Scripts"

# --- SSH config example ---
if [[ ! -f "$HOME/.ssh/config" ]]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cp "$DOTFILES_DIR/.config/ssh_config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    echo "  created: ~/.ssh/config (edit hosts for your network)"
else
    echo "  exists:  ~/.ssh/config (compare with .config/ssh_config.example)"
fi

# --- Create .bashrc.local if it doesn't exist ---
if [[ ! -f "$HOME/.bashrc.local" ]]; then
    cat > "$HOME/.bashrc.local" << 'LOCALEOF'
# ~/.bashrc.local — Machine-specific overrides (not tracked in git)
#
# Examples:
#   export EDITOR="nvim"
#   alias ssh_myserver='ssh user@host'
#   PATH="$HOME/custom/bin:$PATH"
LOCALEOF
    echo "  created: ~/.bashrc.local (add machine-specific overrides here)"
fi

# --- Post-install notes ---
echo ""
echo "Installation complete."

if [[ -d "$BACKUP_DIR" ]]; then
    echo ""
    echo "Backed-up files are in: $BACKUP_DIR"
fi

echo ""
echo "Notes:"
echo "  - Machine-specific settings go in ~/.bashrc.local"
echo "  - To sync changes back to the repo: ./sync_dotfiles.sh"

# --- Optional dependency check ---
echo ""
echo "Checking optional dependencies..."
OPTIONAL_TOOLS=("starship" "fzf" "zoxide" "tmux" "wal" "btop")
missing=()
for tool in "${OPTIONAL_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        missing+=("$tool")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "  Not installed (optional): ${missing[*]}"
    case "$OS" in
        arch|manjaro)
            echo "  Install with: sudo pacman -S ${missing[*]}" ;;
        debian|ubuntu|raspbian)
            echo "  Install with: sudo apt install ${missing[*]}" ;;
        fedora)
            echo "  Install with: sudo dnf install ${missing[*]}" ;;
        macos)
            echo "  Install with: brew install ${missing[*]}" ;;
    esac
else
    echo "  All optional tools found."
fi
