###############################################################################
# Completion for clone — suggest image files (.img, .iso, .raw, .gz, .xz)
###############################################################################
_clone_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local IFS=$'\n'
    COMPREPLY=( $(compgen -f -X '!*.@(img|iso|raw|gz|xz|zip)' -- "$cur") )
    local i
    for i in "${!COMPREPLY[@]}"; do
        if [[ -d "${COMPREPLY[$i]}" ]]; then
            COMPREPLY[$i]="${COMPREPLY[$i]}/"
        fi
    done
}
complete -o nospace -F _clone_completions clone
