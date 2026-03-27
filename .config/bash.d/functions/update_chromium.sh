###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# update_chromium: Update and build the Chromium source, optionally launching it.
# Usage: update_chromium [--run]
update_chromium() {
    set -euo pipefail

    local CHROMIUM_DIR="$HOME/Projects/chromium/src"
    local BUILD_DIR="$CHROMIUM_DIR/out/Default"
    local DEP_SCRIPT="$CHROMIUM_DIR/build/install-build-deps.sh"

    if [[ ! -d "$CHROMIUM_DIR" ]]; then
        echo "Error: Chromium source directory not found at $CHROMIUM_DIR"
        return 1
    fi

    echo "Navigating to Chromium source directory: $CHROMIUM_DIR"
    cd "$CHROMIUM_DIR" || { echo "Failed to change directory to $CHROMIUM_DIR"; return 1; }

    echo "Pulling latest Chromium changes..."
    if ! gclient sync --with_branch_heads --with_tags; then
        echo "Error: gclient sync failed."
        return 1
    fi

    if [[ -f "$DEP_SCRIPT" ]]; then
        echo "Installing missing dependencies..."
        if ! sudo "$DEP_SCRIPT" --no-prompt; then
            echo "Error: Dependency installation failed."
            return 1
        fi
    else
        echo "Warning: Dependency script not found at $DEP_SCRIPT; skipping dependency installation."
    fi

    if [[ ! -d "$BUILD_DIR" ]]; then
        echo "Generating build directory at $BUILD_DIR..."
        if ! gn gen "$BUILD_DIR" --args='is_debug=false is_component_build=false enable_nacl=false'; then
            echo "Error: gn gen failed."
            return 1
        fi
    fi

    echo "Starting Chromium build..."
    if ! autoninja -C "$BUILD_DIR" chrome -j"$(nproc)"; then
        echo "Error: Chromium build failed."
        return 1
    fi

    echo "Chromium build completed successfully."

    if [[ "${1:-}" == "--run" ]]; then
        echo "Launching Chromium..."
        "$BUILD_DIR/chrome" --no-sandbox
    fi
}
