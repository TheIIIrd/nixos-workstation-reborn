#!/bin/bash

set -euo pipefail

# Function to output messages
function echo_info {
    echo -e "\e[32m[INFO]\e[0m $1"
}

function echo_error {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Checking for required utilities
command -v git >/dev/null 2>&1 || { echo_error "git is not installed. Please install git and try again."; exit 1; }
command -v nix-shell >/dev/null 2>&1 || { echo_error "nix-shell is not installed. Please install Nix and try again."; exit 1; }

# Getting default values
default_username="${USER}"
default_hostname="${HOSTNAME}"
default_state_version=$(grep 'system.stateVersion' /etc/nixos/configuration.nix | awk -F'"' '{print $2}')
default_home_manager_state_version="$default_state_version"

# Configuration parameters
read -r -p "Enter your username [$default_username]: " username
username="${username:-$default_username}"

read -r -p "Enter hostname [$default_hostname]: " hostname
hostname="${hostname:-$default_hostname}"

read -r -p "Enter stateVersion [$default_state_version]: " state_version
state_version="${state_version:-$default_state_version}"

read -r -p "Enter home-manager stateVersion [$default_home_manager_state_version]: " home_manager_state_version
home_manager_state_version="${home_manager_state_version:-$default_home_manager_state_version}"

# Cloning the repository
repo_dir="$HOME/.nix"
if [ ! -d "$repo_dir" ]; then
    echo_info "Cloning the repository..."
    git clone https://github.com/TheIIIrd/nixos-workstation-reborn.git "$repo_dir"
else
    echo_info "Repository already exists. Updating..."
    cd "$repo_dir"
    git pull
fi

cd "$repo_dir"

# Copying configuration for the new host
echo_info "Copying configuration for host $hostname..."
if [ ! -d "$hostname" ]; then
    cp -r hosts/nixos "hosts/$hostname"
fi

cd "hosts/$hostname"

# Copying hardware-configuration.nix
echo_info "Copying hardware-configuration.nix..."
cp --no-preserve=mode /etc/nixos/hardware-configuration.nix .

# Editing flake.nix
echo_info "Editing flake.nix..."
flake_file="$repo_dir/flake.nix"
sed -i -e "s/theiiird/$username/g" \
       -e "/{ hostname = \"nixos-blank\"; stateVersion = \"24.05\"; }/d" \
       -e "s/hostname = \"nixos\"/hostname = \"$hostname\"/" \
       -e "s/stateVersion = \"24.11\"/stateVersion = \"$state_version\"/" \
       -e "s/homeStateVersion = \"24.11\"/homeStateVersion = \"$home_manager_state_version\"/" \
       "$flake_file"

# Editing other configuration files
echo_info "Editing other configuration files..."
nano local-packages.nix
nano ../../home-manager/home-packages.nix
nano ../../home-manager/modules/git.nix
nano ../../nixos/modules/default.nix
nano ../../nixos/modules/boot/default.nix
nano ../../nixos/modules/desktop/default.nix
nano ../../nixos/modules/graphics/default.nix

# Prompt to run blockcheck
read -r -p "Do you want to run zapret blockcheck? (Y/n) [y]: " run_blockcheck
run_blockcheck="${run_blockcheck:-y}"

if [[ "$run_blockcheck" =~ ^[Yy]$ ]]; then
    nix-shell -p zapret --command blockcheck
fi

# Opening zapret.nix in nano
nano ../../nixos/modules/zapret.nix

# System rebuild
echo_info "Starting system rebuild..."
cd "$repo_dir"
git add .
sudo nixos-rebuild boot --flake "./#$hostname"

# Message about the need to reboot and run the second script
echo_info "Please reboot the system. After rebooting, run 'bash ./setup_after_reboot.sh' to complete the setup. Note that Zsh setup is not required; it is recommended to skip this step so that home-manager can automatically perform the necessary actions."
