# Function: tar-home
# Description:
#   Create a robust compressed backup of the user's home directory using tar and zstd.
#   Excludes user-defined directories and automatically deletes backups older than a retention period
#   (only if a newer backup exists).
#   Designed to be safe for inclusion in ~/.bashrc and avoids polluting global scope.

###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

tar-home() {
    # Backup configuration
    local backup_dir="$HOME/backups"
    local timestamp archive_name
    local retention_days=14  # Change this to customize how long to keep backups

    command -v tar >/dev/null || { echo "Error: tar is not installed." >&2; return 1; }
    command -v zstd >/dev/null || { echo "Error: zstd is not installed." >&2; return 1; }


    # Directories to exclude from the backup (relative to $HOME)
    local -a exclude_paths=(
        ".cache"
        "Downloads"
        "Videos"
        "GoogleDrive"
        "crawled_data"
        "Debs"
        "Projects"
        ".local/versions"
        "Desktop"
        "firefox-source"
        ".Heaven"
        "models"
        ".mozbuild"
        ".mozilla"
        ".pki"
        "venv"
        "backups"
        "Games"
        ".local/share/Trash"
        ".local/share/flatpak"
    )

    # Internal helper: Build --exclude arguments for tar
    _build_exclude_args() {
        local -a exclude_args=()
        for exclude in "${exclude_paths[@]}"; do
            exclude_args+=( "--exclude=$HOME/$exclude" )
        done
    }

    # Internal helper: Find backups older than $retention_days with no newer ones
    _cleanup_old_backups() {
        local backup_files latest_file old_file
        mapfile -t backup_files < <(find "$backup_dir" -maxdepth 1 -type f -name "home_backup_*.tar.zst" | sort -V)

        if (( ${#backup_files[@]} <= 1 )); then
            return 0  # Nothing to clean up
        fi

        latest_file="${backup_files[-1]}"

        for old_file in "${backup_files[@]}"; do
            if find "$old_file" -prune -mtime +$retention_days -print -quit | grep -q .; then
                echo "Deleting old backup: $old_file"
                rm -f "$old_file"
            fi
        done
    }

    # Generate timestamp and archive filename
    timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
    archive_name="home_backup_${timestamp}.tar.zst"

    # Ensure backup directory exists
    if [[ ! -d "$backup_dir" ]]; then
        echo "Creating backup directory: $backup_dir"
        mkdir -p "$backup_dir" || {
            echo "Error: Failed to create backup directory." >&2
            return 1
        }
    fi

    echo "Starting backup of $HOME to $backup_dir/$archive_name"
    
       # Build exclude arguments into an array
    local -a exclude_args
    mapfile -t exclude_args < <(_build_exclude_args)

    # Run tar with dynamic exclude list
    tar --create \
        --verbose \
        --preserve-permissions \
        --acls \
        --xattrs \
        --numeric-owner \
        --one-file-system \
        --file="$backup_dir/$archive_name" \
        --use-compress-program=zstd \
        "${exclude_args[@]}" \
        "$HOME" || {
            echo "Error: tar command failed." >&2
            return 1
        }


    echo "Backup completed successfully: $backup_dir/$archive_name"

    echo "Checking for old backups to delete (retention: $retention_days days)..."
    _cleanup_old_backups
    
    # Unset helper functions to keep global scope clean
    unset -f _build_exclude_args _cleanup_old_backups

}
