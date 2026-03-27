# Setup fzf
# ---------
if [[ ! "$PATH" == */home/madhatter/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/madhatter/.fzf/bin"
fi

eval "$(fzf --bash)"
