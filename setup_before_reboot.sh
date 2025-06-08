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
        echo_info "Select configuration template:"
        echo "1) Manual configuration (advanced users)"
        echo "2) Desktop configuration"
        echo "3) Laptop configuration"

        while true; do
            read -r -p "$(echo_question "Enter your choice [1-3]: ")" config_type
            case $config_type in
                1)
                    echo_info "Creating manual configuration for host $hostname..."
                    cp -r nixos "$hostname"
                    declare -g config_type="manual"
                    break
                    ;;
                2)
                    if [ -d "nixos-desktop" ]; then
                        echo_info "Creating desktop configuration for host $hostname..."
                        cp -r nixos-desktop "$hostname"
                        declare -g config_type="desktop"
                        break
                    else
                        echo_error "Desktop template not found!"
                    fi
                    ;;
                3)
                    if [ -d "nixos-laptop" ]; then
                        echo_info "Creating laptop configuration for host $hostname..."
                        cp -r nixos-laptop "$hostname"
                        declare -g config_type="laptop"
                        break
                    else
                        echo_error "Laptop template not found!"
                    fi
                    ;;
                *)
                    echo_error "Invalid choice, please try again."
                    ;;
            esac
        done
    else
        echo_info "Using existing host configuration directory: $hostname"
    fi

    cd "$hostname" || { echo_error "Failed to enter host directory"; exit 1; }

    echo_info "Copying hardware configuration..."
    if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
        cp --no-preserve=mode /etc/nixos/hardware-configuration.nix .
    else
        echo_warn "Hardware configuration not found in /etc/nixos/"
    fi
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
    local host_dir="$repo_dir/hosts/$hostname"

    echo_info "Opening configuration files for editing..."

    # Common files for all configurations
    local common_files=(
        "local-packages.nix"
        "../../home-manager/home-packages.nix"
        "../../home-manager/modules/git.nix"
    )

    # Edit common files
    for file in "${common_files[@]}"; do
        if [ -f "$host_dir/$file" ]; then
            nano "$host_dir/$file"
        else
            echo_warn "File $file not found, skipping..."
        fi
    done

    # Configuration-specific files
    case "$config_type" in
        "desktop")
            local specific_files=(
                "../../nixos/modules/nixos-desktop.nix"
            )
            ;;
        "laptop")
            local specific_files=(
                "../../nixos/modules/nixos-laptop.nix"
            )
            ;;
        *)
            local specific_files=(
                "../../nixos/modules/base/default.nix"
                "../../nixos/modules/boot/default.nix"
                "../../nixos/modules/desktop/default.nix"
                "../../nixos/modules/graphics/default.nix"
            )
            ;;
    esac

    # Edit specific files
    for file in "${specific_files[@]}"; do
        if [ -f "$host_dir/$file" ]; then
            nano "$host_dir/$file"
        else
            echo_warn "File $file not found, skipping..."
        fi
    done

    # Additional configuration for desktop/laptop
    if [[ "$config_type" =~ ^(desktop|laptop)$ ]]; then
        # Desktop environment selection
        echo_info "Select desktop environment:"
        echo "1) GNOME"
        echo "2) KDE"
        echo "0) Skip"

        read -r -p "$(echo_question "Enter your choice [0-2]: ")" de_choice
        case "$de_choice" in
            1)
                if [ -f "$host_dir/../../nixos/modules/desktop/gnome.nix" ]; then
                    nano "$host_dir/../../nixos/modules/desktop/gnome.nix"
                else
                    echo_warn "GNOME configuration not found!"
                fi
                ;;
            2)
                if [ -f "$host_dir/../../nixos/modules/desktop/kde.nix" ]; then
                    nano "$host_dir/../../nixos/modules/desktop/kde.nix"
                else
                    echo_warn "KDE configuration not found!"
                fi
                ;;
        esac

        # Graphics configuration
        echo_info "Select graphics configuration:"
        echo "1) Intel"
        echo "2) NVIDIA"
        echo "3) NVIDIA + Intel (hybrid)"
        echo "0) Skip"
        
        read -r -p "$(echo_question "Enter your choice [0-3]: ")" graphics_choice
        case "$graphics_choice" in
            1)
                if [ -f "$host_dir/../../nixos/modules/graphics/intel.nix" ]; then
                    nano "$host_dir/../../nixos/modules/graphics/intel.nix"
                else
                    echo_warn "Intel graphics configuration not found!"
                fi
                ;;
            2)
                if [ -f "$host_dir/../../nixos/modules/graphics/nvidia.nix" ]; then
                    nano "$host_dir/../../nixos/modules/graphics/nvidia.nix"
                else
                    echo_warn "NVIDIA graphics configuration not found!"
                fi
                ;;
            3)
                if [ -f "$host_dir/../../nixos/modules/graphics/nvidia-intel.nix" ]; then
                    nano "$host_dir/../../nixos/modules/graphics/nvidia-intel.nix"
                else
                    echo_warn "Hybrid graphics configuration not found!"
                fi
                ;;
        esac
    fi
}

function run_zapret_check {
    if ask_confirmation "Run zapret blockcheck?"; then
        echo_info "Running zapret blockcheck..."
        nix-shell -p zapret --command blockcheck
    fi
}

function edit_zapret_config {
    local repo_dir="$HOME/.nix"
    if [ -f "$repo_dir/nixos/modules/base/zapret.nix" ]; then
        nano "$repo_dir/nixos/modules/base/zapret.nix"
    else
        echo_warn "Zapret configuration not found!"
    fi
}

function clean_repository {
    local repo_dir="$HOME/.nix"
    cd "$repo_dir" || return 1

    if ask_confirmation "Remove Git-related files (.git, .gitignore)?"; then
        echo_info "Removing Git files..."
        rm -rf .git .gitignore
    fi

    if [ -d "screenshots" ]; then
        if ask_confirmation "Remove screenshots directory?"; then
            echo_info "Removing screenshots..."
            rm -rf screenshots
        fi
    fi

    if [ -f "flake.lock" ]; then
        if ask_confirmation "Remove flake.lock file?"; then
            echo_info "Removing flake.lock..."
            rm -f flake.lock
        fi
    fi
}

function rebuild_system {
    local repo_dir="$HOME/.nix"

    if ask_confirmation "Clean repository before rebuild?"; then
        clean_repository
    fi

    echo_info "Staging changes in git..."
    cd "$repo_dir" || { echo_error "Failed to enter repository directory"; exit 1; }

    if [ -d ".git" ]; then
        git add .
    fi

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
