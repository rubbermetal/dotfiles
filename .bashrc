#!/usr/bin/env bash
###############################################################################
# $HOME/.bashrc — rubbermetal's bash configuration
#
# Shared config (aliases, functions, env, PATH) lives in:
#   $HOME/.config/bash.d/shell_common.sh
#
# This file handles bash-specific settings: history, readline, shopt,
# completions, and prompt.
###############################################################################

# Exit if not interactive
[[ $- != *i* ]] && return

# Require Bash 4+
if (( BASH_VERSINFO[0] < 4 )); then
    echo "This .bashrc requires Bash 4.0+"
    return 1
fi

###############################################################################
# 1. Load shared config (env, PATH, aliases, functions)
###############################################################################

COMMON_SH="$HOME/.config/bash.d/shell_common.sh"
if [[ -f "$COMMON_SH" ]]; then
    source "$COMMON_SH"
else
    echo "Warning: shell_common.sh not found at $COMMON_SH" >&2
fi

###############################################################################
# 2. Source global bash definitions
###############################################################################

if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
elif [[ -f /etc/bash.bashrc ]]; then
    source /etc/bash.bashrc
fi

###############################################################################
# 3. History
###############################################################################

HISTORY_FILE="${DATA_DIR:-$HOME/.config/bash.d/data}/history"
[[ ! -f "$HISTORY_FILE" ]] && touch "$HISTORY_FILE" 2>/dev/null

export HISTFILE="$HISTORY_FILE"
export HISTSIZE=5000000
export HISTFILESIZE=2000000
PROMPT_COMMAND='history -a'
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE='&:ls:l:ll:la:cd:exit:clear:history'
export HSTR_CONFIG=hicolor

###############################################################################
# 4. Shell options (bash-specific)
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

###############################################################################
# 5. Readline key bindings (bash-specific)
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

if [[ "$COLORTERM" ]]; then
    bind '"\e[7~": beginning-of-line'
    bind '"\e[8~": end-of-line'
else
    bind '"\e[1~": beginning-of-line'
    bind '"\e[4~": end-of-line'
fi

###############################################################################
# 6. Bash completions
###############################################################################

# System completions
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# FZF completions and key bindings
if [[ -f /usr/share/fzf/completion.bash ]]; then
    source /usr/share/fzf/completion.bash
fi
if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
fi

# Custom completions
_source_dir "${COMPLETIONS_DIR:-$HOME/.config/bash.d/completions}"

###############################################################################
# 7. Bash-specific command-not-found hook
###############################################################################

if [[ -r /usr/share/doc/pkgfile/command-not-found.bash ]]; then
    source /usr/share/doc/pkgfile/command-not-found.bash
elif [[ -r /etc/command-not-found ]]; then
    source /etc/command-not-found
fi

###############################################################################
# 8. Powerline (bash-specific integration)
###############################################################################

if command -v powerline-daemon &>/dev/null; then
    powerline-daemon -q
    export POWERLINE_BASH_CONTINUATION=1
    export POWERLINE_BASH_SELECT=1
    if [[ -f /usr/share/powerline/bindings/bash/powerline.sh ]]; then
        source /usr/share/powerline/bindings/bash/powerline.sh
    fi
fi

###############################################################################
# 9. FZF (bash init)
###############################################################################

[[ -f "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"

###############################################################################
# 10. Zoxide (bash init)
###############################################################################

command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

###############################################################################
# 11. Fun facts
###############################################################################

if [[ -f "${CONFIG_BASH_DIR:-$HOME/.config/bash.d}/functions/fun-facts.sh" ]]; then
    fun-facts 2>/dev/null
fi

###############################################################################
# 12. Prompt
###############################################################################

DEFAULT_PS1='\[\e[31m\][\A]\[\e[0m\] \[\e[34m\]\u\[\e[0m\]\[\e[32m\]@\h:\[\e[0m\]\[\e[36m\](\W)\[\e[0m\]> \$ '

if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    PS1="$DEFAULT_PS1"
fi

###############################################################################
# 13. Local overrides (per-machine, not tracked in git)
###############################################################################

[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
