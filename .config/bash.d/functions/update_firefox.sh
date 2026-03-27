###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# update_firefox: Update the Firefox source, rebuild it, and optionally run it.
# Usage: update_firefox [--clean] [--run]
update_firefox() {
    local CLEAN_BUILD=false
    local RUN_AFTER_BUILD=false
    local arg

    for arg in "$@"; do
        case "$arg" in
            --clean) CLEAN_BUILD=true ;;
            --run)   RUN_AFTER_BUILD=true ;;
            *)
                echo "Unknown argument: $arg"
                echo "Usage: update_firefox [--clean] [--run]"
                return 1
                ;;
        esac
    done

    if ! command -v hg &>/dev/null; then
        echo "Error: Mercurial (hg) is required but not installed."
        return 1
    fi

    if command -v sccache &>/dev/null; then
        export RUSTC_WRAPPER
        RUSTC_WRAPPER=$(command -v sccache)
        export SCCACHE_DIR="$HOME/.cache/sccache"
    else
        echo "Warning: sccache is not installed. Builds may be slower."
    fi

    local FIREFOX_DIR="$HOME/firefox-source"
    if [[ ! -d "$FIREFOX_DIR" ]]; then
        echo "Error: Firefox source directory not found at $FIREFOX_DIR"
        return 1
    fi

    cd "$FIREFOX_DIR" || { echo "Error: Failed to change directory to $FIREFOX_DIR"; return 1; }

    if [[ ! -x "./mach" ]]; then
        echo "Error: 'mach' script not found or not executable in $FIREFOX_DIR"
        return 1
    fi

    echo "Pulling the latest Firefox changes..."
    hg pull && hg update

    if [[ "$CLEAN_BUILD" == true ]]; then
        echo "Performing a clean build..."
        ./mach clobber
    fi

    echo "Starting the Firefox build..."
    if ./mach build; then
        echo "Firefox build completed successfully."
        if [[ "$RUN_AFTER_BUILD" == true ]]; then
            echo "Launching Firefox..."
            ./mach run
        fi
    else
        echo "Error: Firefox build failed."
        return 1
    fi
}
