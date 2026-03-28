#!/bin/bash
###############################################################################
# install.sh — Deploy dotfiles onto a new (or existing) machine
#
# Usage:
#   ./install.sh              # Install with backups
#   ./install.sh --force      # Overwrite without backups
#   ./install.sh --bootstrap  # Install + install core tools
#   ./install.sh --conky      # Also install Conky desktop widget
#   ./install.sh --uninstall  # Remove symlinks, restore backups
#
# Works on: Debian, Ubuntu, Raspberry Pi OS, Arch, Fedora, macOS
###############################################################################

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
FORCE=false
BOOTSTRAP=false
UNINSTALL=false
CONKY=false

for arg in "$@"; do
    case "$arg" in
        --force)     FORCE=true ;;
        --bootstrap) BOOTSTRAP=true ;;
        --uninstall) UNINSTALL=true ;;
        --conky)     CONKY=true ;;
    esac
done

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

# --- Package manager abstraction ---
pkg_install() {
    case "$OS" in
        arch|manjaro|endeavouros)
            sudo pacman -S --noconfirm --needed "$@" ;;
        debian|ubuntu|raspbian|linuxmint|pop)
            sudo apt-get install -y "$@" ;;
        fedora)
            sudo dnf install -y "$@" ;;
        macos)
            brew install "$@" ;;
        *)
            echo "  Unknown OS '$OS' — install manually: $*" >&2
            return 1 ;;
    esac
}

# --- Helper: symlink with backup ---
link_file() {
    local src="$1"
    local dest="$2"

    [[ ! -e "$src" ]] && return

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

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo "  linked: $dest"
}

# --- Helper: remove symlink if it points to our repo ---
unlink_file() {
    local dest="$1"
    if [[ -L "$dest" ]]; then
        local target
        target="$(readlink "$dest")"
        if [[ "$target" == "$DOTFILES_DIR"* ]]; then
            rm "$dest"
            echo "  removed: $dest"
        fi
    fi
}

# =========================================================================
# UNINSTALL
# =========================================================================
if $UNINSTALL; then
    echo "Uninstalling dotfiles (removing symlinks to $DOTFILES_DIR)..."
    echo ""

    unlink_file "$HOME/.bashrc"
    unlink_file "$HOME/.tmux.conf"
    unlink_file "$HOME/.fzf.bash"
    unlink_file "$HOME/Scripts"
    unlink_file "$HOME/.config/starship.toml"

    for dir in bash.d .Conky alacritty btop macchina neofetch picom sxhkd tmux wallpapers; do
        unlink_file "$HOME/.config/$dir"
    done

    # Remove Conky autostart if present
    unlink_file "$HOME/.config/autostart/conkyx.desktop"

    # Remove zsh integration line if present
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "shell_common.sh" "$HOME/.zshrc"; then
            sed -i '/shell_common\.sh/d' "$HOME/.zshrc"
            echo "  removed: shell_common.sh line from ~/.zshrc"
        fi
    fi

    echo ""
    echo "Uninstall complete."

    # Offer to restore most recent backup
    local_backup="$(ls -td "$HOME/.dotfiles_backup"/*/ 2>/dev/null | head -1)"
    if [[ -n "$local_backup" ]]; then
        echo "Most recent backup: $local_backup"
        echo "To restore: cp -a ${local_backup}* ~/"
    fi
    exit 0
fi

# =========================================================================
# BOOTSTRAP — install core tools
# =========================================================================
if $BOOTSTRAP; then
    echo "Bootstrapping core tools for $OS..."
    echo ""

    # Tools that make the shell experience complete
    CORE_TOOLS=(fzf tmux zoxide btop curl git)

    # Starship needs special handling on some distros
    STARSHIP_NEEDED=false
    if ! command -v starship &>/dev/null; then
        STARSHIP_NEEDED=true
    fi

    # Filter to only missing tools
    to_install=()
    for tool in "${CORE_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            to_install+=("$tool")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        echo "  Installing: ${to_install[*]}"
        pkg_install "${to_install[@]}" || true
    else
        echo "  Core tools already installed."
    fi

    # Starship (install via official script if not in repos)
    if $STARSHIP_NEEDED; then
        echo "  Installing starship..."
        if [[ "$OS" == "arch" || "$OS" == "manjaro" ]]; then
            pkg_install starship || true
        else
            curl -sS https://starship.rs/install.sh | sh -s -- -y 2>/dev/null || true
        fi
    fi

    # pywal (optional, skip on servers)
    if ! command -v wal &>/dev/null; then
        echo "  Skipping pywal (install manually if on desktop: pip install pywal)"
    fi

    echo ""
fi

# =========================================================================
# INSTALL
# =========================================================================
echo "Detected OS: $OS"
echo "Installing dotfiles from $DOTFILES_DIR ..."
echo ""

# --- Detect current shell ---
CURRENT_SHELL="$(basename "$SHELL")"
echo "Current shell: $CURRENT_SHELL"
echo ""

# --- Top-level dotfiles ---
link_file "$DOTFILES_DIR/.bashrc"    "$HOME/.bashrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.fzf.bash"  "$HOME/.fzf.bash"

# --- .config directories ---
CONFIG_DIRS=(
    "bash.d"
    "alacritty"
    "btop"
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

link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/Scripts" "$HOME/Scripts"

# --- SSH config ---
if [[ ! -f "$HOME/.ssh/config" ]]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    cp "$DOTFILES_DIR/.config/ssh_config.example" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    echo "  created: ~/.ssh/config (edit hosts for your network)"
else
    echo "  exists:  ~/.ssh/config"
fi

# --- Zsh integration ---
if [[ "$CURRENT_SHELL" == "zsh" || -f "$HOME/.zshrc" ]]; then
    echo ""
    echo "  Zsh detected."
    INJECT_LINE='[[ -f ~/.config/bash.d/shell_common.sh ]] && emulate sh -c '\''source ~/.config/bash.d/shell_common.sh'\'''

    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "shell_common.sh" "$HOME/.zshrc"; then
            echo "  ~/.zshrc already sources shell_common.sh"
        else
            echo "" >> "$HOME/.zshrc"
            echo "# --- Dotfiles: shared aliases, functions, env ---" >> "$HOME/.zshrc"
            echo "$INJECT_LINE" >> "$HOME/.zshrc"
            echo "  appended: shell_common.sh source line to ~/.zshrc"
        fi
    else
        # No .zshrc exists — deploy our standalone one
        link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    fi
fi

# --- Bash local overrides ---
if [[ ! -f "$HOME/.bashrc.local" ]]; then
    cat > "$HOME/.bashrc.local" << 'LOCALEOF'
# ~/.bashrc.local — Machine-specific overrides (not tracked in git)
#
# Examples:
#   export EDITOR="nvim"
#   alias ssh_myserver='ssh user@host'
#   PATH="$HOME/custom/bin:$PATH"
LOCALEOF
    echo "  created: ~/.bashrc.local"
fi

# --- Machine profile ---
if [[ ! -f "$HOME/.dotfiles_profile" ]]; then
    echo ""
    echo "  Machine profile not set. Auto-detecting..."
    if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        profile="desktop"
    elif [[ -n "${SSH_CONNECTION:-}" ]]; then
        profile="server"
    else
        profile="minimal"
    fi
    echo "$profile" > "$HOME/.dotfiles_profile"
    echo "  created: ~/.dotfiles_profile ($profile)"
    echo "  Change anytime: echo desktop|server|minimal > ~/.dotfiles_profile"
fi

# =========================================================================
# CONKY — Optional desktop widget
# =========================================================================
# Auto-offer on desktop profile, or install with --conky flag
PROFILE="$(cat "$HOME/.dotfiles_profile" 2>/dev/null || echo "minimal")"

if ! $CONKY && [[ "$PROFILE" == "desktop" ]]; then
    echo ""
    echo "  Desktop profile detected. Install Conky widget? [y/N]"
    read -r -t 10 conky_answer || conky_answer=""
    [[ "$conky_answer" =~ ^[Yy] ]] && CONKY=true
fi

if $CONKY; then
    echo ""
    echo "Installing Conky widget..."

    # Link the .Conky directory
    link_file "$DOTFILES_DIR/.config/.Conky" "$HOME/.config/.Conky"

    # Make shell scripts executable
    chmod +x "$DOTFILES_DIR/.config/.Conky/conkyx/scripts/sh/"* 2>/dev/null
    chmod +x "$DOTFILES_DIR/.config/.Conky/conkyx/bin/"* 2>/dev/null

    # Install conky if not present
    if ! command -v conky &>/dev/null; then
        echo "  Installing conky..."
        pkg_install conky || echo "  Warning: could not install conky automatically" >&2
    fi

    # Install fonts if the font directories exist
    FONT_DIR="$DOTFILES_DIR/.config/.Conky/conkyx/fonts"
    if [[ -d "$FONT_DIR" ]]; then
        LOCAL_FONTS="$HOME/.local/share/fonts"
        mkdir -p "$LOCAL_FONTS"
        fonts_installed=0
        for font_subdir in "$FONT_DIR"/*/; do
            [[ -d "$font_subdir" ]] || continue
            for ttf in "$font_subdir"/*.ttf "$font_subdir"/*.otf; do
                [[ -f "$ttf" ]] || continue
                fname="$(basename "$ttf")"
                if [[ ! -f "$LOCAL_FONTS/$fname" ]]; then
                    cp "$ttf" "$LOCAL_FONTS/"
                    fonts_installed=$((fonts_installed + 1))
                fi
            done
        done
        if [[ $fonts_installed -gt 0 ]]; then
            echo "  installed: $fonts_installed fonts to $LOCAL_FONTS"
            fc-cache -f "$LOCAL_FONTS" 2>/dev/null || true
        else
            echo "  fonts: already installed"
        fi
    fi

    # Try to compile C scripts if gcc is available
    CONKY_C_SRC="$DOTFILES_DIR/.config/.Conky/conkyx/scripts/C/Source"
    if command -v gcc &>/dev/null && [[ -f "$CONKY_C_SRC/Makefile" ]]; then
        echo "  Compiling C helper scripts..."
        if make -C "$CONKY_C_SRC" install 2>/dev/null; then
            echo "  compiled: C scripts built and installed"
        else
            echo "  skipped: C compilation failed (shell scripts will be used)"
        fi
    else
        echo "  skipped: gcc not found (shell scripts will be used as backend)"
    fi

    # Create autostart entry for desktop environments
    AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$AUTOSTART_DIR"
    CONKY_START="$HOME/.config/.Conky/conkyx/bin/conkyx-start.sh"
    cat > "$AUTOSTART_DIR/conkyx.desktop" << DESKEOF
[Desktop Entry]
Type=Application
Name=Conkyx System Monitor
Exec=$CONKY_START
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
DESKEOF
    echo "  created: autostart entry for Conky"

    echo "  Conky installed. Start with: ~/.config/.Conky/conkyx/bin/conkyx-start.sh"
    echo "  Override backend: CONKY_BACKEND=sh (or c, py)"
    echo "  Override weather: CONKY_WEATHER_LOCATION=<zip>"
fi

# --- Install dotfiles command ---
DOTFILES_BIN="$HOME/.local/bin/dotfiles"
mkdir -p "$HOME/.local/bin"
cat > "$DOTFILES_BIN" << BINEOF
#!/bin/bash
# dotfiles — manage your dotfiles
DOTFILES_DIR="$DOTFILES_DIR"

case "\${1:-help}" in
    update)
        echo "Pulling latest dotfiles..."
        cd "\$DOTFILES_DIR" && git pull origin main
        ;;
    sync)
        "\$DOTFILES_DIR/sync_dotfiles.sh"
        ;;
    install)
        shift
        "\$DOTFILES_DIR/install.sh" "\$@"
        ;;
    edit)
        \${EDITOR:-nano} "\$DOTFILES_DIR"
        ;;
    profile)
        if [[ -n "\${2:-}" ]]; then
            echo "\$2" > "\$HOME/.dotfiles_profile"
            echo "Profile set to: \$2"
        else
            echo "Current profile: \$(cat "\$HOME/.dotfiles_profile" 2>/dev/null || echo 'not set')"
            echo "Usage: dotfiles profile <desktop|server|minimal>"
        fi
        ;;
    health)
        shell_health 2>/dev/null || echo "shell_health not loaded — source your shell config first"
        ;;
    dir)
        echo "\$DOTFILES_DIR"
        ;;
    help|*)
        echo "Usage: dotfiles <command>"
        echo ""
        echo "Commands:"
        echo "  update    Pull latest from git"
        echo "  sync      Sync live config into the repo and push"
        echo "  install   Re-run the installer"
        echo "  edit      Open the dotfiles directory in \$EDITOR"
        echo "  profile   View or set machine profile (desktop/server/minimal)"
        echo "  health    Run shell health check"
        echo "  dir       Print dotfiles directory path"
        ;;
esac
BINEOF
chmod +x "$DOTFILES_BIN"
echo "  installed: dotfiles command (~/.local/bin/dotfiles)"

# =========================================================================
# SUMMARY
# =========================================================================
echo ""
echo "Installation complete."

if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backed-up files: $BACKUP_DIR"
fi

echo ""
echo "Quick start:"
echo "  dotfiles update     — pull latest from git"
echo "  dotfiles sync       — push local changes to git"
echo "  dotfiles profile    — view/set machine profile"
echo "  dotfiles health     — check tool availability"

# --- Dependency check ---
echo ""
echo "Checking dependencies..."
OPTIONAL_TOOLS=("starship" "fzf" "zoxide" "tmux" "btop")
missing=()
for tool in "${OPTIONAL_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        missing+=("$tool")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "  Not installed: ${missing[*]}"
    if ! $BOOTSTRAP; then
        echo "  Run: ./install.sh --bootstrap  to install them"
    fi
else
    echo "  All tools found."
fi
