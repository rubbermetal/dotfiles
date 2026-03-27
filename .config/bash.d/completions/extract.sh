###############################################################################
# Completion for extract — suggest archive files
###############################################################################
_extract_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=$'\n'
    COMPREPLY=( $(compgen -f -X '!*.@(tar|tar.gz|tar.bz2|tar.xz|tgz|tbz2|gz|bz2|zip|rar|7z|z)' -- "$cur") )
    # Append / to directories so navigation works
    local i
    for i in "${!COMPREPLY[@]}"; do
        if [[ -d "${COMPREPLY[$i]}" ]]; then
            COMPREPLY[$i]="${COMPREPLY[$i]}/"
        fi
    done
}
complete -o nospace -F _extract_completions extract
