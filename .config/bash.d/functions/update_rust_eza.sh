###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# update_rust_eza: Ensures the latest Rust (Nightly) is installed and updates
# the eza project by pulling the latest code and rebuilding it.
###############################################################################
update_rust_eza() {
    local rustup_url="https://sh.rustup.rs"
    local rust_project_dir="$HOME/Projects/eza"

    echo "=== Checking for rustup installation ==="
    if ! command -v rustup &>/dev/null; then
        echo "rustup not found. Installing rustup..."
        if ! curl --proto '=https' --tlsv1.2 -sSf "$rustup_url" | sh -s -- -y --default-toolchain nightly; then
            echo "Error: Failed to install rustup."
            return 1
        fi
        # Update PATH so that rustup and Cargo are immediately available.
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "rustup is already installed."
    fi

    echo "=== Ensuring Rust is set to nightly ==="
    if ! rustc --version | grep -q "nightly"; then
        echo "Rust is not on nightly. Setting toolchain to nightly..."
        if ! rustup default nightly; then
            echo "Error: Failed to set rustup default to nightly."
            return 1
        fi
        if ! rustup override set nightly; then
            echo "Error: Failed to set rustup override to nightly."
            return 1
        fi
    else
        echo "Rust is already set to nightly."
    fi

    echo "=== Updating Rust toolchain ==="
    if ! rustup update; then
        echo "Error: rustup update failed."
        return 1
    fi

    echo "=== Updating Cargo and cargo-update ==="
    if ! cargo install cargo-update; then
        echo "Warning: cargo-update may already be installed."
    fi
    if ! cargo install-update -a; then
        echo "Error: cargo install-update failed."
        return 1
    fi

    echo "=== Checking eza project directory ==="
    if [[ ! -d "$rust_project_dir" ]]; then
        echo "Error: eza source directory not found at $rust_project_dir"
        return 1
    fi

    echo "=== Updating and building eza ==="
    if ! cd "$rust_project_dir"; then
        echo "Error: Failed to enter eza directory."
        return 1
    fi

    if ! git pull; then
        echo "Error: git pull failed in $rust_project_dir."
        return 1
    fi

    if ! cargo clean; then
        echo "Error: cargo clean failed."
        return 1
    fi

    if ! cargo build --release; then
        echo "Error: cargo build failed."
        return 1
    fi

    echo "=== Installation complete! ==="
    echo "The new eza binary is located at:"
    echo "$rust_project_dir/target/release/eza"
}
