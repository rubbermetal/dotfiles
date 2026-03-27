###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# Function: install_kickstart_nvim
# Purpose:
#   Remove any existing Neovim configuration and install Kickstart.nvim
#   by cloning its repository into ~/.config/nvim.
# Requirements:
#   - Git must be installed.
###############################################################################
install_kickstart_nvim() {
    local repo_url="https://github.com/nvim-lua/kickstart.nvim.git"
    local config_dir="$HOME/.config/nvim"

    # Check if Git is installed.
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is not installed. Please install Git and try again."
        return 1
    fi

    # Check if the Neovim configuration directory already exists.
    if [ -d "$config_dir" ]; then
        echo "The directory '$config_dir' already exists."
        read -p "Do you want to remove the existing directory? (y/n): " user_choice
        if [ "$user_choice" = "y" ] || [ "$user_choice" = "Y" ]; then
            rm -rf "$config_dir" || {
                echo "Error: Failed to remove directory '$config_dir'."
                return 1
            }
            echo "Removed the existing directory '$config_dir'."
        else
            echo "Aborted installation. Please remove or rename the existing directory and try again."
            return 1
        fi
    fi

    # Clone the Kickstart.nvim repository.
    echo "Cloning Kickstart.nvim from $repo_url into $config_dir..."
    git clone "$repo_url" "$config_dir" || {
        echo "Error: Failed to clone repository from $repo_url."
        return 1
    }
    echo "Kickstart.nvim installed successfully in '$config_dir'."
}

###############################################################################
# Function: update_neovim
# Purpose:
#   Update Neovim installed from source by pulling the latest changes,
#   recompiling, and installing it.
# Requirements:
#   - Your Neovim source should be in ~/Projects/neovim.
###############################################################################
update_neovim() {
    local nvim_source_dir="$HOME/Projects/neovim"

    # Check if the Neovim source directory exists.
    if [ ! -d "$nvim_source_dir" ]; then
        echo "Error: Neovim source directory '$nvim_source_dir' not found."
        return 1
    fi

    # Change to the Neovim source directory.
    cd "$nvim_source_dir" || {
        echo "Error: Could not change directory to '$nvim_source_dir'."
        return 1
    }

    # Pull the latest changes from the repository.
    echo "Pulling the latest changes in $nvim_source_dir..."
    git pull || {
        echo "Error: Failed to pull the latest changes."
        return 1
    }

    # Compile Neovim.
    echo "Compiling Neovim..."
    make CMAKE_BUILD_TYPE=Release || {
        echo "Error: Compilation of Neovim failed."
        return 1
    }

    # Install Neovim.
    echo "Installing Neovim..."
    sudo make install || {
        echo "Error: Installation of Neovim failed."
        return 1
    }

    echo "Neovim updated successfully."
}
