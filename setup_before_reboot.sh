#!/bin/bash

set -euo pipefail

# Colors for output
GREEN='\e[32m'
RED='\e[31m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

# Function to output messages
function echo_info {
    echo -e "${GREEN}[INFO]${RESET} $1"
}

function echo_warn {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

function echo_error {
    echo -e "${RED}[ERROR]${RESET} $1"
}

function echo_question {
    echo -e "${BLUE}[QUESTION]${RESET} $1"
}

function ask_confirmation {
    local prompt="$1 (Y/n): "
    local default="${2:-y}"
    read -r -p "$(echo_question "$prompt")" response
    response="${response:-$default}"
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

function check_requirements {
    command -v git >/dev/null 2>&1 || { echo_error "git is not installed. Please install git and try again."; exit 1; }
    command -v nix-shell >/dev/null 2>&1 || { echo_error "nix-shell is not installed. Please install Nix and try again."; exit 1; }
}

function get_config_values {
    local default_username="${USER}"
    local default_hostname="${HOSTNAME}"
    local default_state_version=$(grep 'system.stateVersion' /etc/nixos/configuration.nix | awk -F'"' '{print $2}')
    local default_home_manager_state_version="$default_state_version"

    read -r -p "$(echo_question "Enter your username [$default_username]: ")" username
    username="${username:-$default_username}"

    read -r -p "$(echo_question "Enter hostname [$default_hostname]: ")" hostname
    hostname="${hostname:-$default_hostname}"

    read -r -p "$(echo_question "Enter stateVersion [$default_state_version]: ")" state_version
    state_version="${state_version:-$default_state_version}"

    read -r -p "$(echo_question "Enter home-manager stateVersion [$default_home_manager_state_version]: ")" home_manager_state_version
    home_manager_state_version="${home_manager_state_version:-$default_home_manager_state_version}"

    declare -g username hostname state_version home_manager_state_version
}

function setup_repository {
    local repo_dir="$HOME/.nix"

    if [ ! -d "$repo_dir" ]; then
        echo_info "Cloning the repository..."
        git clone https://github.com/TheIIIrd/nixos-workstation-reborn.git "$repo_dir"
        cd "$repo_dir"

        if ask_confirmation "Switch to gen-v2 branch?"; then
            echo_info "Switching to gen-v2 branch..."
            git checkout gen-v2
        else
            echo_info "Keeping main branch"
        fi
    else
        echo_info "Updating existing repository..."
        cd "$repo_dir"
        git pull

        current_branch=$(git branch --show-current)
        echo_info "Current branch: $current_branch"

        if ask_confirmation "Would you like to switch branches?"; then
            echo_info "Available branches:"
            git branch -a

            # Безопасный ввод имени ветки
            echo_question "Enter branch name to switch to (e.g., main, gen-v2): "
            read -r branch_name
            if git checkout "$branch_name" 2>/dev/null; then
                echo_info "Switched to $branch_name branch"
                git pull
            else
                echo_error "Branch $branch_name not found!"
            fi
        fi
    fi
}

function configure_host {
    local hostname="$1"
    local repo_dir="$HOME/.nix"

    cd "$repo_dir/hosts" || { echo_error "Failed to enter hosts directory"; exit 1; }

    if [ ! -d "$hostname" ]; then
        echo_info "Creating configuration for host $hostname..."
        cp -r nixos "$hostname"
    fi

    cd "$hostname" || { echo_error "Failed to enter host directory"; exit 1; }

    echo_info "Copying hardware configuration..."
    cp --no-preserve=mode /etc/nixos/hardware-configuration.nix .
}

function edit_flake {
    local repo_dir="$HOME/.nix"
    local flake_file="$repo_dir/flake.nix"

    echo_info "Configuring flake.nix..."
    sed -i -e "s/theiiird/$username/g" \
           -e "/{ hostname = \"nixos-blank\"; stateVersion = \"24.05\"; }/d" \
           -e "s/hostname = \"nixos\"/hostname = \"$hostname\"/" \
           -e "s/stateVersion = \"24.11\"/stateVersion = \"$state_version\"/" \
           -e "s/homeStateVersion = \"24.11\"/homeStateVersion = \"$home_manager_state_version\"/" \
           "$flake_file"
}

function edit_config_files {
    local repo_dir="$HOME/.nix"

    echo_info "Opening configuration files for editing..."
    local files_to_edit=(
        "local-packages.nix"
        "../../home-manager/home-packages.nix"
        "../../home-manager/modules/git.nix"
        "../../nixos/modules/base/default.nix"
        "../../nixos/modules/boot/default.nix"
        "../../nixos/modules/desktop/default.nix"
        "../../nixos/modules/graphics/default.nix"
    )

    for file in "${files_to_edit[@]}"; do
        if [ -f "$repo_dir/hosts/$hostname/$file" ]; then
            nano "$repo_dir/hosts/$hostname/$file"
        else
            echo_warn "File $file not found, skipping..."
        fi
    done
}

function run_zapret_check {
    if ask_confirmation "Run zapret blockcheck?"; then
        echo_info "Running zapret blockcheck..."
        nix-shell -p zapret --command blockcheck
    fi
}

function edit_zapret_config {
    local repo_dir="$HOME/.nix"
    nano "$repo_dir/nixos/modules/base/zapret.nix"
}

function rebuild_system {
    local repo_dir="$HOME/.nix"

    echo_info "Staging changes in git..."
    cd "$repo_dir" || { echo_error "Failed to enter repository directory"; exit 1; }
    git add .

    echo_info "Rebuilding system configuration..."
    sudo nixos-rebuild boot --flake "./#$hostname"
}

function main {
    echo_info "Starting NixOS configuration setup..."

    check_requirements
    get_config_values
    setup_repository
    configure_host "$hostname"
    edit_flake
    edit_config_files
    run_zapret_check
    edit_zapret_config
    rebuild_system

    echo_info "Configuration complete!"
    echo_info "Please reboot the system."
    echo_info "After rebooting, run 'bash ./setup_after_reboot.sh' to complete the setup."
    echo_info "Note: Zsh setup is not required; skip this step to let home-manager handle it automatically."
}

main "$@"
