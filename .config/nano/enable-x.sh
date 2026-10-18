# 256-color nano syntax for st and other X terminals.
# Source from an interactive shell. The Linux console keeps nanorc.
# Usage: nano file.py    or    nano-x file.py
case ${TERM-} in
  *256color*|*-direct*)
    if [ -f "${HOME}/.config/nano/xnanorc" ]; then
      nano() { command nano -f "${HOME}/.config/nano/xnanorc" "$@"; }
    fi
    if [ -z "${EDITOR-}" ] && [ -x "${HOME}/.local/bin/nano-x" ]; then
      export EDITOR="${HOME}/.local/bin/nano-x"
    fi
    if [ -z "${VISUAL-}" ] && [ -x "${HOME}/.local/bin/nano-x" ]; then
      export VISUAL="${HOME}/.local/bin/nano-x"
    fi
    ;;
esac
