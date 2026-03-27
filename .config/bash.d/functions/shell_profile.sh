###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# shell_profile — Benchmark shell startup by timing each sourced file
#
# Usage: shell_profile
#
# Launches a new bash instance that times every file sourced by .bashrc,
# then prints a sorted report showing the slowest files first.
###############################################################################
shell_profile() {
    local profile_script
    profile_script=$(mktemp /tmp/bash_profile_XXXXXX.sh)

    cat > "$profile_script" << 'PROFEOF'
#!/bin/bash
# Intercept 'source' and '.' to time each file
_profile_log=$(mktemp /tmp/bash_profile_log_XXXXXX)

_time_ms() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        python3 -c 'import time; print(int(time.time()*1000))'
    else
        date +%s%3N
    fi
}

_original_source=$(which source 2>/dev/null || echo "builtin source")

source() {
    local file="$1"
    local start end elapsed
    start=$(_time_ms)
    builtin source "$@"
    local ret=$?
    end=$(_time_ms)
    elapsed=$((end - start))
    echo "${elapsed} ${file}" >> "$_profile_log"
    return $ret
}

.() { source "$@"; }

# Source the actual bashrc
builtin source "$HOME/.bashrc"

echo ""
echo "=== Shell Startup Profile (slowest first) ==="
echo ""
if [[ -f "$_profile_log" ]]; then
    sort -rn "$_profile_log" | head -20 | while read -r ms file; do
        printf "  %6d ms  %s\n" "$ms" "$file"
    done
    echo ""
    total=$(awk '{s+=$1} END {print s}' "$_profile_log")
    echo "  Total: ${total} ms across $(wc -l < "$_profile_log") files"
fi

rm -f "$_profile_log"
PROFEOF

    bash --norc --noprofile "$profile_script"
    rm -f "$profile_script"
}
