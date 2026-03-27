#!/bin/bash
    2 
    3 # Function to check for required commands
    4 check_command() {
    5     command -v "$1" &>/dev/null || { echo "Error: '$1' is           not installed. Install it and try again."; exit 1; }
    6 }
    7 
    8 # Ensure required commands exist
    9 check_command git
   10 check_command ssh
   11 check_command curl
   12 
   13 echo "Configuring Git..."
   14 
   15 # Prompt user for Git configuration details
   16 read -rp "Enter your full name (for Git commits): " git_n      ame                                                      
   17 read -rp "Enter your Git email address: " git_email
   18 read -rp "Enter your GitHub username: " github_username
   19 
   20 # Set Git global configuration
   21 git config --global user.name "$git_name"
   22 git config --global user.email "$git_email"
   23 git config --global core.editor "vim"  # Change to your p      referred editor
   
echo "Git global configuration set successfully."
   26 
   27 # Offer to generate SSH key
   28 read -rp "Would you like to generate an SSH key for GitHu      b? (y/n): " generate_ssh
   29 
   30 if [[ "$generate_ssh" == "y" ]]; then
   31     ssh_key_path="$HOME/.ssh/id_rsa"
   32 
   33     if [[ -f "$ssh_key_path" ]]; then
   34         echo "SSH key already exists at $ssh_key_path."  
   35     else
   36         echo "Generating a new SSH key..."
   37         ssh-keygen -t rsa -b 4096 -C "$git_email" -f "$ss              h_key_path" -N ""
   38         echo "SSH key generated at $ssh_key_path."
   39     fi
   40 
   41     eval "$(ssh-agent -s)"
   42     ssh-add "$ssh_key_path"
   43 
   44     echo "Adding SSH key to GitHub..."
   45     github_key=$(<"$ssh_key_path.pub")
   47     response=$(curl -s -o /dev/null -w "%{http_code}" -u           "$github_username" --data "{\"title\":\"$(hostname) -           $(date)\",\"key\":\"$github_key\"}" https://api.gith          ub.com/user/keys)
   48 
   49     if [[ "$response" == "201" ]]; then
   50         echo "SSH key added to GitHub successfully!"     
   51     else
   52         echo "Failed to add SSH key to GitHub. You may ne              ed to add it manually."
   53     fi
   54 else
   55     echo "Skipping SSH key setup."
   56 fi
   57 
   58 echo "Git setup complete!"
~
