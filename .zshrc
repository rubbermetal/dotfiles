###############################################################################
# Dotfiles zsh integration — source this from your existing .zshrc
#
# Add this line to the END of your .zshrc (after oh-my-zsh loads):
#   [[ -f ~/.config/bash.d/shell_common.sh ]] && emulate sh -c 'source ~/.config/bash.d/shell_common.sh'
#
# Or if you want the full standalone .zshrc (no oh-my-zsh), rename this
# file to ~/.zshrc directly.
###############################################################################

# --- This file is a STANDALONE .zshrc for machines without oh-my-zsh ---
# --- On machines WITH oh-my-zsh, only the source line above is needed ---

[[ $- != *i* ]] && return

###############################################################################
# 1. Load shared config (env, PATH, aliases, functions)
###############################################################################

COMMON_SH="$HOME/.config/bash.d/shell_common.sh"
if [[ -f "$COMMON_SH" ]]; then
    emulate sh -c "source $COMMON_SH"
fi

###############################################################################
# 2. History
###############################################################################

HISTFILE="${DATA_DIR:-$HOME/.config/bash.d/data}/history_zsh"
HISTSIZE=5000000
SAVEHIST=2000000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt APPEND_HISTORY

###############################################################################
# 3. Zsh options
###############################################################################

setopt AUTO_CD
setopt CDABLE_VARS
setopt NO_CASE_GLOB
setopt GLOB_DOTS
setopt EXTENDED_GLOB
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

###############################################################################
# 4. Completion system
###############################################################################

autoload -Uz compinit
compinit -C

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%B%d%b'

compdef '_files -g "*.tar* *.gz *.bz2 *.xz *.zip *.rar *.7z *.z"' extract
compdef _directories mkcd
compdef _directories fzcd

###############################################################################
# 5. Key bindings
###############################################################################

bindkey -e
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[A'  up-line-or-search
bindkey '^[[B'  down-line-or-search

###############################################################################
# 6. FZF
###############################################################################

if [[ -f "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
elif command -v fzf &>/dev/null; then
    eval "$(fzf --zsh 2>/dev/null)" || true
fi

###############################################################################
# 7. Zoxide
###############################################################################

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

###############################################################################
# 8. Prompt (fallback if starship/p10k not available)
###############################################################################

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{red}[%T]%f %F{blue}%n%f%F{green}@%m:%f%F{cyan}(%1~)%f> '
fi

###############################################################################
# 9. Local overrides
###############################################################################

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
