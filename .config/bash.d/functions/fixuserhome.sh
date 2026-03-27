###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

# fixuserhome: Fix permissions in a user's home folder.
fixuserhome() {
    local username="${1:-$(whoami)}"
    if [[ ! -d "/home/${username}" ]]; then
        echo "Error: User '${username}' does not have a home folder."
        return 1
    fi
    local hourglass="\033[0;33m⧗\033[0m"
    local checkmark="\r\033[1;32m✔\033[0m"
    if ask "\033[1;31mWARNING:\033[0m Change all permissions for user \033[0;36m${username}\033[0m's home folder?" N; then
        sudo true
        if ask "Reset group ownership to \033[0;36m${username}\033[0m?" Y; then
            echo -ne "${hourglass} Setting owner and group as ${username}..."
            sudo chown -R "${username}:${username}" "/home/${username}"
        else
            echo -ne "${hourglass} Setting owner as ${username}..."
            sudo chown -R "${username}" "/home/${username}"
        fi
        echo -e "${checkmark}"
        echo -ne "${hourglass} Ensuring user has read and write access..."
        chmod -R u+rw "/home/${username}"
        echo -e "${checkmark}"
        echo -ne "${hourglass} Removing write access from group..."
        chmod -R g-w "/home/${username}"
        echo -e "${checkmark}"
        echo -ne "${hourglass} Removing all access from others..."
        chmod -R o-rwx "/home/${username}"
        echo -e "${checkmark}"
        echo -ne "${hourglass} Making shell scripts executable..."
        find "/home/${username}" -type f \( -name "*.sh" -o -name ".*.sh" \) -exec chmod ug+x {} \;
        echo -e "${checkmark}"
        echo -ne "${hourglass} Ensuring directories have execute permission..."
        chmod -R ug+X "/home/${username}"
        echo -e "${checkmark}"
        echo -ne "${hourglass} Removing group execute on directories without group read..."
        find "/home/${username}" -type d ! -perm -g+r -exec chmod g-wx {} \;
        echo -e "${checkmark}"
        echo -ne "${hourglass} Setting the setgid bit on the home directory..."
        chmod g+s "/home/${username}"
        echo -e "${checkmark}"
        if command -v setfacl &>/dev/null; then
            echo -ne "${hourglass} Modifying default ACL entries..."
            setfacl -d -m u::rwx "/home/${username}"
            setfacl -d -m g::rx "/home/${username}"
            setfacl -d -m o::X "/home/${username}"
            echo -e "${checkmark}"
        fi
        echo "Done!"
    fi
}
