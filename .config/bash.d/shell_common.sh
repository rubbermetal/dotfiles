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
for _d in "$HOME/Scripts" "$HOME/.local/bin"; do
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

# True when a command word is a program, builtin, function, or other alias.
# A word equal to the alias being checked must be a real command, not that alias.
_dotfiles_have_word() {
    _w=$1
    _self=$2
    [ -n "$_w" ] || return 0
    case $_w in
        \$*|\'*|\"*) return 0 ;;
    esac
    if [ -n "${ZSH_VERSION-}" ]; then
        if [ "$_w" = "$_self" ]; then
            whence -p "$_w" >/dev/null 2>&1 && return 0
            whence -w "$_w" 2>/dev/null | grep -q ': \(builtin\|function\|reserved\)$' && return 0
            return 1
        fi
        whence -p "$_w" >/dev/null 2>&1 && return 0
        whence -w "$_w" 2>/dev/null | grep -q ': \(builtin\|function\|reserved\|alias\)$' && return 0
        return 1
    fi
    if [ "$_w" = "$_self" ]; then
        type -P "$_w" >/dev/null 2>&1 && return 0
        case $(type -t "$_w" 2>/dev/null) in
            builtin|function|keyword) return 0 ;;
        esac
        return 1
    fi
    type -P "$_w" >/dev/null 2>&1 && return 0
    case $(type -t "$_w" 2>/dev/null) in
        builtin|function|keyword|alias) return 0 ;;
    esac
    return 1
}

# Drop an alias whose program is not installed. New files in aliases/ get the same check.
_dotfiles_alias_body_ok() {
    _self=$1
    _body=$2
    case $_body in
        \'*\') _body=${_body#\'}; _body=${_body%\'} ;;
    esac
    _flat=$(printf '%s\n' "$_body" | tr '|&;' '\n')
    _saveifs=$IFS
    IFS='
'
    for _seg in $_flat; do
        IFS=$_saveifs
        set -f
        # shellcheck disable=SC2086
        set -- $_seg
        set +f
        _cmd=
        _saw_sudo=0
        for _word in "$@"; do
            [ -n "$_word" ] || continue
            case $_word in
                *=*) [ -z "$_cmd" ] && [ "$_saw_sudo" -eq 0 ] && continue ;;
            esac
            case $_word in
                -*) [ "$_saw_sudo" -eq 1 ] && continue ;;
            esac
            if [ "$_word" = sudo ] && [ -z "$_cmd" ]; then
                _saw_sudo=1
                continue
            fi
            _cmd=$_word
            break
        done
        if [ -n "$_cmd" ] && ! _dotfiles_have_word "$_cmd" "$_self"; then
            IFS=$_saveifs
            return 1
        fi
        IFS='
'
    done
    IFS=$_saveifs
    return 0
}

_dotfiles_drop_missing_aliases() {
    _lines=$(alias 2>/dev/null || true)
    [ -n "$_lines" ] || return 0
    _saveifs=$IFS
    IFS='
'
    for _line in $_lines; do
        IFS=$_saveifs
        _item=$_line
        case $_item in
            alias\ *) _item=${_item#alias } ;;
        esac
        _name=${_item%%=*}
        _body=${_item#*=}
        [ -n "$_name" ] || continue
        if ! _dotfiles_alias_body_ok "$_name" "$_body"; then
            unalias "$_name" 2>/dev/null || true
        fi
        IFS='
'
    done
    IFS=$_saveifs
}

_source_dir "$FUNCTIONS_DIR"
_source_dir "$ALIASES_DIR"
_dotfiles_drop_missing_aliases
