###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# shell_health — Report on shell environment after sourcing
#
# Shows which optional tools are available and which are missing.
# Run manually: shell_health
###############################################################################
shell_health() {
    local -a found=() missing=()

    local -a tools=(
        "starship:prompt"
        "fzf:fuzzy finder"
        "zoxide:smart cd"
        "tmux:terminal multiplexer"
        "wal:pywal theming"
        "btop:system monitor"
        "eza:modern ls"
        "bat:modern cat"
        "fd:modern find"
        "rg:ripgrep"
        "git:version control"
        "curl:http client"
        "python3:python"
        "node:nodejs"
    )

    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}"
        local desc="${entry#*:}"
        if command -v "$cmd" &>/dev/null; then
            found+=("$cmd ($desc)")
        else
            missing+=("$cmd ($desc)")
        fi
    done

    echo "=== Shell Health Check ==="
    echo ""

    if [[ ${#found[@]} -gt 0 ]]; then
        echo "Available:"
        for item in "${found[@]}"; do
            echo "  + $item"
        done
    fi

    echo ""

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Not installed (optional):"
        for item in "${missing[@]}"; do
            echo "  - $item"
        done
    else
        echo "All optional tools installed."
    fi

    echo ""

    # Check shell config
    local issues=()
    [[ ! -f "$HOME/.ssh/config" ]] && issues+=("~/.ssh/config missing — SSH aliases won't resolve")
    [[ ! -f "$HOME/.bashrc.local" ]] && issues+=("~/.bashrc.local missing — no machine-specific overrides")
    [[ ! -d "$HOME/.tmux/plugins/tpm" ]] && issues+=("TPM not installed — tmux plugins won't load")

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "Warnings:"
        for issue in "${issues[@]}"; do
            echo "  ! $issue"
        done
    fi
}
