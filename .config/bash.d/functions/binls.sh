binls() {
    local bin_dir="$HOME/.local/bin"
    local prefix selected matches

    if [[ ! -d $bin_dir ]]; then
        echo "lsbin: directory not found: $bin_dir" >&2
        return 1
    fi

    if [[ -n $1 ]]; then
        prefix="$1"
        shift
    else
        read -rp "lsbin prefix: " prefix
    fi

    matches=$(find "$bin_dir" -maxdepth 1 -type f -printf "%f\n" \
              | grep -E "^${prefix}")

    if [[ -z $matches ]]; then
        echo "lsbin: no matches for prefix '$prefix'" >&2
        return 1
    fi

    selected=$(printf '%s\n' "$matches" \
        | fzf --exact --no-sort \
              --prompt="run ~/.local/bin/ > " \
              --preview "batcat --style=numbers --color=always --paging=never \"$bin_dir/{}\"" \
              --preview-window=right:70%:wrap)

    if [[ -z $selected ]]; then
        echo "lsbin: no selection made." >&2
        return 1
    fi

    exec "$bin_dir/$selected" "$@"
}
