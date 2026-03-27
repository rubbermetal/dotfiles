###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# addpath: Add (or remove) a directory to/from an environment variable.
# Default variable is PATH; use the optional parameters "first" to add at the
# beginning or "remove" to delete the entry.
###############################################################################
addpath() {
    shopt -s extglob
    local new_entry="$1"
    local position="${2:-}"  # Options: "first", "remove", or empty (append)
    local verbose="${3:-}"

    # Helper functions for verbose output and joining arrays.
    __addpath_verb() { [[ -n "$verbose" ]] && echo "-- $1"; }
    __addpath_join() { local IFS="${AP_VAR_DELIM}"; echo "$*"; }

    # Use defaults if not set.
    [[ -z "${AP_VAR_NAME}" ]] && AP_VAR_NAME="PATH"
    [[ -z "${AP_VAR_DELIM}" ]] && AP_VAR_DELIM=":"

    # For Bash 4+, build an associative array to avoid duplicates.
    if (( BASH_VERSINFO[0] >= 4 )); then
        declare -A current_paths
        local index=0
        IFS="${AP_VAR_DELIM}" read -r -a path_array <<< "${!AP_VAR_NAME}"
        for path in "${path_array[@]}"; do
            current_paths["$path"]="$index"
            ((index++))
        done
    else
        __addpath_verb "Warning: Old Bash version detected. Some features are disabled."
        if [[ "$position" == "first" ]]; then
            eval "${AP_VAR_NAME}=\"${new_entry}${AP_VAR_DELIM}\$(eval echo \${${AP_VAR_NAME}})\""
            __addpath_verb "Added ${new_entry} to beginning of ${AP_VAR_NAME}"
        elif [[ "$position" == "remove" ]]; then
            __addpath_verb "Removal requested; skipping re-addition of '${new_entry}'."
        else
            eval "${AP_VAR_NAME}=\"\$(eval echo \${${AP_VAR_NAME}})${AP_VAR_DELIM}${new_entry}\""
            __addpath_verb "Added ${new_entry} to end of ${AP_VAR_NAME}"
        fi
        export "${AP_VAR_NAME}"
        unset AP_VAR_NAME
        return
    fi

    # Remove trailing slash from new_entry.
    [[ "$new_entry" =~ (.+)/$ ]] && new_entry="${BASH_REMATCH[1]}"
    if [[ ! -d "$new_entry" ]]; then
        __addpath_verb "Error: ${new_entry} does not exist or is not a directory."
        [[ "$position" == "remove" ]] && __addpath_verb "Removal requested."
        unset AP_VAR_NAME
        return
    fi

    # Rebuild PATH without the new_entry (if already present).
    local updated_paths=()
    for p in "${!current_paths[@]}"; do
        if [[ "$p" != "$new_entry" ]]; then
            updated_paths+=( "$p" )
        else
            __addpath_verb "${new_entry} is already in ${AP_VAR_NAME}."
            [[ "$position" != "remove" ]] && { __addpath_verb "Not re-adding."; unset AP_VAR_NAME; return; }
        fi
    done

    if [[ "$position" == "first" ]]; then
        updated_paths=( "$new_entry" "${updated_paths[@]}" )
        __addpath_verb "Added ${new_entry} to beginning of ${AP_VAR_NAME}"
    elif [[ "$position" == "remove" ]]; then
        __addpath_verb "Removed ${new_entry} from ${AP_VAR_NAME}"
    else
        updated_paths+=( "$new_entry" )
        __addpath_verb "Added ${new_entry} to end of ${AP_VAR_NAME}"
    fi

    eval "${AP_VAR_NAME}=\"\$(__addpath_join ${updated_paths[@]})\""
    export "${AP_VAR_NAME}"
    unset AP_VAR_NAME
}
