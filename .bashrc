#!/usr/bin/env bash
###############################################################################
# $HOME/.bashrc
#
# rubbermetal's bashrc
#
# This file loads additional configuration files from:
#   $HOME/.config/.bash.d/
#
# It is designed to work across Debian, Arch, and other major distros.
#
# Indemnity: By using this script, you agree to indemnify and hold harmless the
# author from any and all claims, damages, or losses arising from its use.
#
# MIT License (License text omitted for brevity)
###############################################################################

###############################################################################
# 1. Exit Early Checks
###############################################################################

# Exit if the shell is not interactive.
if [[ $- != *i* ]]; then
    return
fi

# Require at least Bash 4.
if (( BASH_VERSINFO[0] < 4 )); then
    echo "This .bashrc file requires at least Bash 4.0"
    exit 1
fi

###############################################################################
# 2. Core Environment Variables and Paths
###############################################################################

# Configuration directory for additional bash files
CONFIG_BASH_DIR="$HOME/.config/bash.d"
FUNCTIONS_DIR="$CONFIG_BASH_DIR/functions"
ALIASES_DIR="$CONFIG_BASH_DIR/aliases"
DATA_DIR="$CONFIG_BASH_DIR/data"
HISTORY_FILE="$DATA_DIR/history"
FACTS_FILE="$DATA_DIR/facts.txt"
declare -A required_dirs=(
    [PROJECTS]="$HOME/Projects"
    [TORRENTS]="$HOME/torrents"
    [SCRIPTS]="$HOME/Scripts"
    [APPS]="$HOME/apps"
    [LOCAL_BIN]="$HOME/.local/bin"
)
if [[ ! -f "$HISTORY_FILE" ]]; then
    if ! touch "$HISTORY_FILE"; then
        echo "Warning: Could not create history file at $HISTORY_FILE"
    fi
fi

for var_name in "${!required_dirs[@]}"; do
    dir_path="${required_dirs[$var_name]}"
    if [[ ! -d "$dir_path" ]]; then
        if ! mkdir -p "$dir_path"; then
            echo "Error: Unable to create directory $dir_path" >&2
            exit 1
        fi
    fi
    # Assign the directory path to the global variable named by var_name.
    declare -g "$var_name"="$dir_path"
done
###############################################################################
# 3. Source Global Definitions
###############################################################################

if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
elif [[ -f /etc/bash.bashrc ]]; then
    source /etc/bash.bashrc
fi

###############################################################################
# 4. Terminal and Display Settings
###############################################################################

# Enable 256-color terminals.
export TERM=xterm-256color
export use_color=true
# Enable icons for ls. option always, auto, none
export LS_ICONS_MODE=always
# Tell ncurses to use UTF-8.
export NCURSES_NO_UTF8_ACS=1

# Enable the "command not found" hook if available.
if [[ -r /usr/share/doc/pkgfile/command-not-found.bash ]]; then
    source /usr/share/doc/pkgfile/command-not-found.bash
elif [[ -r /etc/command-not-found ]]; then
    source /etc/command-not-found
fi

# Enable true color support for Micro editor.
export MICRO_TRUECOLOR=1

# Toggle upgrade notifications (Arch, Ubuntu, etc.)
_SKIP_UPGRADE_NOTIFY=true

# Configure key bindings for help
_SKIP_HELP_KEYBIND=false

###############################################################################
# 5. Local Configuration Files
###############################################################################

# Source config files in a specific order

for config_file in \
    "$CONFIG_BASH_DIR"/config/colors \
    "$CONFIG_BASH_DIR"/config/attributes 
    do
        [[ -f "$config_file" ]] && source "$config_file"
    done

# Source any available function scripts
if [[ -d "$FUNCTIONS_DIR" ]]; then
    for func_file in "$FUNCTIONS_DIR"/*.sh; do
        if [[ -r "$func_file" ]]; then
            source "$func_file"
        else
            echo "Warning: Cannot read function file: $func_file" >&2
        fi
    done
fi

# Source any available alias scripts
if [[ -d "$ALIASES_DIR" ]]; then
    for alias_file in "$ALIASES_DIR"/*.sh; do
        if [[ -r "$alias_file" ]]; then
            source "$alias_file"
        else
            echo "Warning: Cannot read alias file: $alias_file" >&2
        fi
    done
fi


###############################################################################
# 6. Additional Utilities / Completions
###############################################################################

# Load bash-completion if available
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# Load fzf completion if available
if [[ -f /usr/share/fzf/completion.bash ]]; then
    source /usr/share/fzf/completion.bash
fi

# Load fzf key bindings if available
if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
fi

###############################################################################
# 7. Display System/HUD (Optional)
###############################################################################

command -v wal &>/dev/null && wal -R 2>/dev/null
display_system_info

# Disable screen blanking and power saving features
if command -v xset >/dev/null 2>&1; then
    # Only run if X server is running
    if [ -n "$DISPLAY" ]; then
        xset s off              # Turn off screen saver
        xset -dpms              # Disable DPMS (Energy Star) features
        xset s noblank          # Don't blank the video device
    fi
fi

###############################################################################
# 8. Default Text Editor
###############################################################################

if command -v nano &>/dev/null; then
    export EDITOR="nano"
elif command -v nvim &>/dev/null; then
    export EDITOR="nvim"
elif command -v emacs &>/dev/null; then
    export EDITOR="emacs -nw"
else
    export EDITOR="vim"
fi

###############################################################################
# 9. Flatpak and XDG Data Dirs
###############################################################################

if [[ ":$XDG_DATA_DIRS:" != *":/var/lib/flatpak/exports/share:"* ]]; then
    export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
fi

###############################################################################
# 10. systemctl Helper Functions
###############################################################################

if command -v systemctl &>/dev/null; then
    start()   { sudo systemctl start   "$1.service"; }
    restart() { sudo systemctl restart "$1.service"; }
    stop()    { sudo systemctl stop    "$1.service"; }
    enable()  { sudo systemctl enable  "$1.service"; }
    status()  { sudo systemctl status  "$1.service"; }
    disable() { sudo systemctl disable "$1.service"; }
fi

###############################################################################
# 11. History Settings
###############################################################################

export HISTFILE="$HISTORY_FILE"
export HISTSIZE=5000000
export HISTFILESIZE=2000000
PROMPT_COMMAND='history -a'
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE='&:ls:l:ll:la:cd:exit:clear:history'
export HSTR_CONFIG=hicolor

###############################################################################
# 12. Readline Key Bindings
###############################################################################

bind '"\C-h": "\C-a history | fzf -e \C-j"'
bind '"\C-xk": "\C-a history | fzf -k \C-j"'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind 'set mark-symlinked-directories on'
bind 'set mark-directories on'
bind 'set expand-tilde off'
bind 'set colored-stats on'
bind 'set visible-stats on'
bind Space:magic-space

# Fix Home and End keys for Putty/xterm
if [[ "$COLORTERM" ]]; then
    bind '"\e[7~": beginning-of-line'
    bind '"\e[8~": end-of-line'
else
    bind '"\e[1~": beginning-of-line'
    bind '"\e[4~": end-of-line'
fi

###############################################################################
# 13. Additional Shell Options
###############################################################################

shopt -s checkwinsize
shopt -s histappend histverify
shopt -s cmdhist
shopt -s expand_aliases
shopt -s extglob
shopt -s autocd 2>/dev/null
shopt -s dirspell 2>/dev/null
shopt -s direxpand 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s sourcepath
shopt -s cdable_vars
shopt -s globstar 2>/dev/null
shopt -s nocaseglob
shopt -s checkhash
shopt -s dotglob
shopt -s no_empty_cmd_completion

# Optionally restrict or modify completion
# complete -cf sudo

# Optionally disable logout with Ctrl+D
# set -o ignoreeof

###############################################################################
# 14. Styled MAN Pages (If X is Running)
###############################################################################

_isxrunning=false
if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
    _isxrunning=true
fi

if $_isxrunning; then
    export PAGER=less
    export LESS_TERMCAP_mb=$'\E[5m'  # example: blink
    export LESS_TERMCAP_md=$'\E[1m'  # bold
    export LESS_TERMCAP_me=$'\E[0m'
    export LESS_TERMCAP_se=$'\E[0m'
    export LESS_TERMCAP_so=$'\E[7m'
    export LESS_TERMCAP_ue=$'\E[24m'
    export LESS_TERMCAP_us=$'\E[4m'
fi

###############################################################################
# 15. Powerline Fonts/Bash Integration
###############################################################################

if command -v powerline-daemon &>/dev/null; then
    powerline-daemon -q
    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1
    if [[ -f /usr/share/powerline/bindings/bash/powerline.sh ]]; then
        source /usr/share/powerline/bindings/bash/powerline.sh
    else
        echo "Warning: Powerline script not found."
    fi
fi

###############################################################################
# 16. PATH Updates
###############################################################################

declare -a additional_paths=(
    "$HOME/.local/bin"
    "$HOME/Scripts"
    "/opt/bin"
    "$HOME/perl5/bin"
    "$HOME/Projects/depot_tools"
    "$HOME/.config/emacs/bin"
    "/usr/sbin"
)

for directory in "${additional_paths[@]}"; do
    if [[ -d "$directory" ]] && [[ ":$PATH:" != *":$directory:"* ]]; then
        PATH="$directory:$PATH"
    fi
done
export PATH

###############################################################################
# 17. Perl Environment (If Relevant)
###############################################################################

if [[ -d "$HOME/perl5" ]]; then
    PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
    PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
    PERL_MB_OPT="--install_base \"$HOME/perl5\""
    PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT
fi

###############################################################################
# 18. Source Cargo for Rust
###############################################################################

if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

###############################################################################
# 19. Source fzf
###############################################################################

if [[ -f "$HOME/.fzf.bash" ]]; then
    source "$HOME/.fzf.bash"
fi

###############################################################################
# 20. Fun Facts or Other Scripts
###############################################################################

if [[ -f "$CONFIG_BASH_DIR/functions/fun-facts.sh" ]]; then
    fun-facts
fi

###############################################################################
# 21. Zoxide
###############################################################################

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

###############################################################################
# 22. Prompt Customization
###############################################################################

# Define fallback PS1
DEFAULT_PS1='\[\e[31m\][\A]\[\e[0m\] \[\e[34m\]\u\[\e[0m\]\[\e[32m\]@\h:\[\e[0m\]\[\e[36m\](\W)\[\e[0m\]> \$ '

# If Starship is installed, use it; otherwise fallback
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    PS1="$DEFAULT_PS1"
fi

###############################################################################
# 23. Local Overrides (per-machine, not tracked in git)
###############################################################################

if [[ -f "$HOME/.bashrc.local" ]]; then
    source "$HOME/.bashrc.local"
fi

###############################################################################
# End of .bashrc
###############################################################################
