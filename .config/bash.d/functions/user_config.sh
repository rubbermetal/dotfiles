###############################################################################
# Prevent Direct Execution
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is meant to be sourced, not executed directly."
    exit 1
fi

###############################################################################
# User Home Permission Fixer and Config Copy
###############################################################################

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

# configcopy: Copy configuration files from one account to another.
configcopy() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo -e "Usage: configcopy <from_user> <to_user>"
        return 1
    elif [[ "$1" == "$2" ]]; then
        echo -e "\033[1;31mError:\033[0m The from and to user parameters cannot be the same."
        return 2
    fi

    local dir_from dir_to owner
    if [[ "$1" == "default" ]]; then
        dir_from="/etc/skel/"
        dir_to="/home/$2/"
        owner="$2"
    elif [[ "$2" == "default" ]]; then
        dir_from="/home/$1/"
        dir_to="/etc/skel/"
        owner="root"
    elif [[ "$1" == "root" ]]; then
        dir_from="/root/"
        dir_to="/home/$2/"
        owner="$2"
    elif [[ "$2" == "root" ]]; then
        dir_from="/home/$1/"
        dir_to="/root/"
        owner="root"
    else
        dir_from="/home/$1/"
        dir_to="/home/$2/"
        owner="$2"
    fi

    if ! ask "Are you sure? This will overwrite configuration files in ${dir_to%/}" N; then
        return
    fi

    declare -a files=()
    [[ -f "${dir_from}.bash_logout" ]]  && files+=(".bash_logout")
    [[ -f "${dir_from}.bash_profile" ]] && files+=(".bash_profile")
    [[ -f "${dir_from}.bashrc" ]]       && files+=(".bashrc")
    [[ -f "${dir_from}.bashrc_help" ]]  && files+=(".bashrc_help")
    [[ -f "${dir_from}.inputrc" ]]      && files+=(".inputrc")
    [[ -f "${dir_from}.nanorc" ]]       && files+=(".nanorc")
    [[ -f "${dir_from}.p10k.zsh" ]]     && files+=(".p10k.zsh")
    [[ -f "${dir_from}.screenrc" ]]     && files+=(".screenrc")
    [[ -f "${dir_from}.vimrc" ]]        && files+=(".vimrc")
    [[ -f "${dir_from}.Xauthority" ]]   && files+=(".Xauthority")
    [[ -f "${dir_from}.zshrc" ]]        && files+=(".zshrc")
    for file in "${files[@]}"; do
        sudo cp "${dir_from}${file}" "${dir_to}" 2>/dev/null
        sudo chown "${owner}:${owner}" "${dir_to}${file}"
        echo -e "\033[1;32m✔\033[0m Copied: \033[1;36m${file}\033[0m"
    done

    if [[ -d "${dir_from}.config/bashrc" ]]; then
        sudo mkdir -p "${dir_to}.config"
        sudo cp -R "${dir_from}.config/bashrc" "${dir_to}.config/" 2>/dev/null
        echo -e "\033[1;32m✔\033[0m Copied: Bashrc Config"
    fi
    if [[ -d "${dir_from}.config/fish" ]]; then
        sudo mkdir -p "${dir_to}.config"
        sudo cp -R "${dir_from}.config/fish" "${dir_to}.config/" 2>/dev/null
        echo -e "\033[1;32m✔\033[0m Copied: Fish"
    fi
    if [[ -f "${dir_from}.config/micro/settings.json" ]]; then
        sudo mkdir -p "${dir_to}.config/micro"
        sudo cp "${dir_from}.config/micro/settings.json" "${dir_to}.config/micro/settings.json" 2>/dev/null
        sudo cp "${dir_from}.config/micro/bindings.json" "${dir_to}.config/micro/bindings.json" 2>/dev/null
        sudo cp -R "${dir_from}.config/micro/plug" "${dir_to}.config/micro/" 2>/dev/null
        echo -e "\033[1;32m✔\033[0m Copied: Micro"
    fi

    sudo cp -R "${dir_from}".tmux* "${dir_to}" 2>/dev/null
    if [[ -e "${dir_to}.tmux.conf" ]]; then
        sudo chown "${owner}:${owner}" "${dir_to}.tmux.conf"
        echo -e "\033[1;32m✔\033[0m Copied: Tmux"
    fi
    if [[ -d "${dir_to}.tmux" ]]; then
        sudo chown -R "${owner}:${owner}" "${dir_to}.tmux"
    fi

    echo -e "Owner set to: \033[1;35m${owner}\033[0m"
    echo -e "\033[1;33mFinished\033[0m copying configuration files from \033[1;34m${dir_from%/}\033[0m to \033[1;34m${dir_to%/}\033[0m"
}
