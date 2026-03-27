###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Dictionary and Directory Functions
###############################################################################

# define: Lookup definition of a word using Google.
define() {
    if [[ -z "$1" ]]; then
        echo "Usage: define <word>"
        return 1
    fi
    local tmp_dir="$HOME/.tmp"
    mkdir -p "$tmp_dir"
    local temp_file="${tmp_dir}/templookup.txt"
    if ! command -v elinks &>/dev/null; then
        echo "Error: 'elinks' is required for this function."
        return 1
    fi
    elinks -dump "http://www.google.com/search?hl=en&q=define%3A+${1}" \
        | grep -m 3 -w "*" \
        | sed 's/;/ -/g' \
        | cut -d- -f1 > "$temp_file"
    if [[ -s "$temp_file" ]]; then
        while IFS= read -r line; do
            echo "$line"
        done < "$temp_file"
    else
        echo "Sorry ${USER}, no definition found for \"${1}\"."
    fi
    rm -f "$temp_file"
}
