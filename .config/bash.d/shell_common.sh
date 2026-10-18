#!/usr/bin/env sh
###############################################################################
# shell_common.sh — Shared config loaded by both .bashrc and .zshrc
#
# Contains: environment variables, PATH, editor, aliases, functions,
# and anything that works in both bash and zsh.
#
# Shell-specific things (readline, shopt, completions, prompt) stay in
# their respective rc files.
###############################################################################

# --- Detect current shell ---
if [ -n "$ZSH_VERSION" ]; then
    CURRENT_SHELL="zsh"
elif [ -n "$BASH_VERSION" ]; then
    CURRENT_SHELL="bash"
else
    CURRENT_SHELL="sh"
fi
export CURRENT_SHELL

# Per-machine paths (ccache, a local toolchain). This file is not in the repo.
if [ -f "${HOME}/.config/dotfiles-machine.sh" ]; then
    . "${HOME}/.config/dotfiles-machine.sh"
fi

# --- Detect machine profile ---
# Checks for display server, then falls back to ~/.dotfiles_profile
detect_profile() {
    # User override
    if [ -f "$HOME/.dotfiles_profile" ]; then
        cat "$HOME/.dotfiles_profile"
        return
    fi
    # Auto-detect
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        echo "desktop"
    elif [ -n "$SSH_CONNECTION" ]; then
        echo "server"
    else
        echo "minimal"
    fi
}
DOTFILES_PROFILE="$(detect_profile)"
export DOTFILES_PROFILE

# --- Core directories ---
CONFIG_BASH_DIR="$HOME/.config/bash.d"
FUNCTIONS_DIR="$CONFIG_BASH_DIR/functions"
ALIASES_DIR="$CONFIG_BASH_DIR/aliases"
COMPLETIONS_DIR="$CONFIG_BASH_DIR/completions"
DATA_DIR="$CONFIG_BASH_DIR/data"
FACTS_FILE="$DATA_DIR/facts.txt"
export CONFIG_BASH_DIR FUNCTIONS_DIR ALIASES_DIR COMPLETIONS_DIR DATA_DIR FACTS_FILE

# Create required directories
for _d in "$HOME/Projects" "$HOME/Scripts" "$HOME/apps" "$HOME/.local/bin"; do
    [ -d "$_d" ] || mkdir -p "$_d" 2>/dev/null
done
unset _d

# --- Terminal settings ---
# Leave TERM as the tty set it. The Linux console is TERM=linux.
export use_color=true
export LS_ICONS_MODE=always
export NCURSES_NO_UTF8_ACS=1
export MICRO_TRUECOLOR=1

# --- Default editor ---
if [ -x "$HOME/.local/bin/nano-x" ]; then
    export EDITOR="$HOME/.local/bin/nano-x"
elif command -v nano >/dev/null 2>&1; then
    export EDITOR="nano"
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v emacs >/dev/null 2>&1; then
    export EDITOR="emacs -nw"
else
    export EDITOR="vim"
fi

# --- PATH ---
for _p in \
    "$HOME/.local/bin" \
    "$HOME/Scripts" \
    "/opt/bin" \
    "$HOME/perl5/bin" \
    "$HOME/Projects/depot_tools" \
    "$HOME/.config/emacs/bin" \
    "/usr/sbin"
do
    if [ -d "$_p" ]; then
        case ":$PATH:" in
            *":$_p:"*) ;;
            *) PATH="$_p:$PATH" ;;
        esac
    fi
done
unset _p
export PATH

# --- Flatpak ---
case ":$XDG_DATA_DIRS:" in
    *":/var/lib/flatpak/exports/share:"*) ;;
    *) export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS" ;;
esac

# --- Perl ---
if [ -d "$HOME/perl5" ]; then
    PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
    PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
    PERL_MB_OPT="--install_base \"$HOME/perl5\""
    PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT
fi

# --- Rust ---
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# --- Styled man pages ---
export PAGER=less
export LESS_TERMCAP_mb=$'\E[5m'
export LESS_TERMCAP_md=$'\E[1m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[7m'
export LESS_TERMCAP_ue=$'\E[24m'
export LESS_TERMCAP_us=$'\E[4m'

# --- systemctl helpers (work in any shell) ---
if command -v systemctl >/dev/null 2>&1; then
    start()   { sudo systemctl start   "$1.service"; }
    restart() { sudo systemctl restart "$1.service"; }
    stop()    { sudo systemctl stop    "$1.service"; }
    enable()  { sudo systemctl enable  "$1.service"; }
    status()  { sudo systemctl status  "$1.service"; }
    disable() { sudo systemctl disable "$1.service"; }
fi

# --- Source config files ---
for _cf in "$CONFIG_BASH_DIR"/config/colors "$CONFIG_BASH_DIR"/config/attributes; do
    [ -f "$_cf" ] && . "$_cf"
done
unset _cf

# --- Source functions and aliases ---
# A file this shell cannot parse is skipped. The rest of the directory still loads.
# Signature is mtime plus name. GNU stat -c, otherwise BSD stat -f.
_dotfiles_dir_sig() {
    local dir="$1" sample listing
    sample=$(find "$dir" -name '*.sh' -type f 2>/dev/null | head -n 1)
    [ -n "$sample" ] || return 0
    if stat -c '%Y' "$sample" >/dev/null 2>&1; then
        listing=$(find "$dir" -name '*.sh' -type f -exec stat -c '%Y %n' {} + 2>/dev/null)
    elif stat -f '%m' "$sample" >/dev/null 2>&1; then
        listing=$(find "$dir" -name '*.sh' -type f -exec stat -f '%m %N' {} + 2>/dev/null)
    else
        return 0
    fi
    [ -n "$listing" ] || return 0
    printf '%s\n' "$listing" | sort | cksum | awk '{print $1}'
}

_source_dir() {
    local dir="$1" _f _shell _sig _cache _sigfile
    [ -d "$dir" ] || return 0
    if [ -n "${ZSH_VERSION-}" ]; then
        _shell=zsh
    elif [ -n "${BASH_VERSION-}" ]; then
        _shell=bash
    else
        _shell=sh
    fi
    _cache=""
    if [ "$_shell" = zsh ] || [ "$_shell" = bash ]; then
        mkdir -p "${HOME}/.cache/dotfiles" 2>/dev/null || true
        _sig=$(_dotfiles_dir_sig "$dir")
        _cache="${HOME}/.cache/dotfiles/skip-${_shell}-$(basename "$dir")"
        _sigfile="${_cache}.sig"
        if [ -z "$_sig" ] || [ ! -f "$_sigfile" ] || [ "$(cat "$_sigfile" 2>/dev/null)" != "$_sig" ]; then
            : > "$_cache"
            for _f in "$dir"/*.sh; do
                [ -r "$_f" ] || continue
                _bad=0
                if [ "$_shell" = zsh ]; then
                    zsh -n "$_f" >/dev/null 2>&1 || _bad=1
                    zsh --emulate sh -n "$_f" >/dev/null 2>&1 || _bad=1
                elif [ "$_shell" = bash ]; then
                    bash -n "$_f" >/dev/null 2>&1 || _bad=1
                fi
                [ "$_bad" -eq 0 ] && continue
                echo "$_f" >> "$_cache"
                echo "dotfiles: skipped $_f (this shell cannot parse it)" >&2
            done
            if [ -n "$_sig" ]; then
                echo "$_sig" > "$_sigfile"
            else
                rm -f "$_sigfile"
            fi
        fi
    fi
    for _f in "$dir"/*.sh; do
        [ -r "$_f" ] || continue
        if [ -n "$_cache" ] && [ -s "$_cache" ] && grep -qxF "$_f" "$_cache"; then
            continue
        fi
        . "$_f" || true
    done
}

_source_dir "$FUNCTIONS_DIR"
_source_dir "$ALIASES_DIR"
