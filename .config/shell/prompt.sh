# Prompt for interactive bash and zsh.
#
#   [ -f "$HOME/.config/shell/prompt.sh" ] && . "$HOME/.config/shell/prompt.sh"
#
# TERM=linux keeps the phosphor box prompt (palette when stdout is a tty).
# Otherwise Oh My Posh, then Starship, then a plain prompt.
# Oh My Posh wins when both programs are installed.
# Theme: ~/.config/oh-my-posh/hack.omp.json

if [ -n "${ZSH_VERSION-}" ]; then
  _prompt_shell=zsh
elif [ -n "${BASH_VERSION-}" ]; then
  _prompt_shell=bash
else
  return 0
fi

_prompt_omp=$(command -v oh-my-posh 2>/dev/null || true)
_prompt_theme="${HOME}/.config/oh-my-posh/hack.omp.json"

if [ "${TERM-}" = linux ]; then
  if [ -t 1 ] && [ -f "${HOME}/.local/share/console-palette.sh" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.local/share/console-palette.sh"
    console_palette
  fi
  if [ "$_prompt_shell" = zsh ]; then
    hack_prompt() {
      local gitb='' dirty='' gitseg='' errseg='' sig='%B%F{green}'
      gitb=$(git symbolic-ref --short HEAD 2>/dev/null) || gitb=''
      if [ -n "$gitb" ]; then
        gitb=${gitb//\%/%%}
        if [ -n "$(git --no-optional-locks status --porcelain --ignore-submodules=dirty 2>/dev/null)" ]; then
          dirty='*'
        fi
        gitseg="%F{green}-[%F{cyan}▶ ${gitb}${dirty}%F{green}]"
      fi
      if [ "${hack_status:-0}" -ne 0 ]; then
        errseg="%F{red} × ${hack_status}"
        sig='%B%F{red}'
      fi
      print -nr -- "%F{green}┌──(%B%F{white}%n%b%F{green}@%B%F{white}%m%b%F{green})-[%F{cyan}%(4~|.../%3~|%~)%F{green}]${gitseg}${errseg}"$'\n'"%F{green}└─${sig}\$%b%f "
    }
    hack_precmd() {
      hack_status=$?
    }
    setopt PROMPT_SUBST
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd hack_precmd
    PROMPT='$(hack_prompt)'
    PS2='%F{green}└─%B>%b%f '
  else
    PS1='\[\e[32m\]┌──(\[\e[1;37m\]\u\[\e[0;32m\]@\[\e[1;37m\]\h\[\e[0;32m\])-[\[\e[36m\]\w\[\e[32m\]]\n└─\[\e[1;32m\]$\[\e[0m\] '
  fi
elif [ -n "$_prompt_omp" ]; then
  if [ -f "$_prompt_theme" ]; then
    eval "$("$_prompt_omp" init "$_prompt_shell" --config "$_prompt_theme")"
  else
    eval "$("$_prompt_omp" init "$_prompt_shell")"
  fi
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init "$_prompt_shell")"
else
  if [ "$_prompt_shell" = zsh ]; then
    PROMPT='%F{red}[%T]%f %F{blue}%n%f%F{green}@%m:%f%F{cyan}(%1~)%f> '
  else
    PS1='\[\e[31m\][\A]\[\e[0m\] \[\e[34m\]\u\[\e[0m\]\[\e[32m\]@\h:\[\e[0m\]\[\e[36m\](\W)\[\e[0m\]> \$ '
  fi
fi

unset _prompt_shell _prompt_omp _prompt_theme
