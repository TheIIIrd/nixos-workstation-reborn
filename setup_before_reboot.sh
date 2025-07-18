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

function choose_template {
    echo_question "Choose configuration template:"
    echo "1) Manual configuration (nixos)"
    echo "2) Desktop template (nixos-desktop)"
    echo "3) Laptop template (nixos-laptop)"

    while true; do
        read -r -p "$(echo_question "Enter your choice [1]: ")" choice
        choice="${choice:-1}"

        case "$choice" in
            1) template="nixos"; break ;;
            2) template="nixos-desktop"; break ;;
            3) template="nixos-laptop"; break ;;
            *) echo_error "Invalid choice. Please enter 1, 2 or 3." ;;
        esac
    done

    echo_info "Selected template: $template"
    declare -g template
}

function setup_repository {
    local repo_dir="$HOME/.nix"

    if [ ! -d "$repo_dir" ]; then
        echo_info "Cloning the repository..."
        git clone https://github.com/TheIIIrd/nixos-workstation-reborn.git "$repo_dir"
        cd "$repo_dir"

        if ask_confirmation "Switch to unstable branch?"; then
            echo_info "Switching to unstable branch..."
            git checkout unstable
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

            echo_question "Enter branch name to switch to (e.g., main, ): "
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

function backup_existing_host {
    local hostname="$1"
    local repo_dir="$HOME/.nix/hosts"
    local backup_count=1
    local backup_dir="${hostname}.backup-${backup_count}"

    # Find next available backup directory name
    while [ -d "$repo_dir/$backup_dir" ]; do
        backup_count=$((backup_count + 1))
        backup_dir="${hostname}.backup-${backup_count}"
    done

    echo_info "Backing up existing configuration to $backup_dir"
    mv "$repo_dir/$hostname" "$repo_dir/$backup_dir"
}

function configure_host {
    local hostname="$1"
    local template="$2"
    local repo_dir="$HOME/.nix"

    cd "$repo_dir/hosts" || { echo_error "Failed to enter hosts directory"; exit 1; }

    # Backup existing configuration if it exists
    if [ -d "$hostname" ]; then
        echo_warn "Configuration for $hostname already exists!"
        if ask_confirmation "Backup existing configuration?"; then
            backup_existing_host "$hostname"
        else
            if ask_confirmation "Overwrite existing configuration?"; then
                echo_info "Removing existing configuration..."
                rm -rf "$hostname"
            else
                echo_error "Configuration aborted by user"
                exit 1
            fi
        fi
    fi

    # Check if template exists, otherwise use fallback
    if [ ! -d "$template" ]; then
        echo_warn "Template $template not found! Using fallback templates..."

        local fallback_template=""
        for t in nixos nixos-desktop nixos-laptop; do
            if [ -d "$t" ]; then
                fallback_template="$t"
                break
            fi
        done

        if [ -z "$fallback_template" ]; then
            echo_error "No valid templates found in hosts directory!"
            exit 1
        fi

        echo_info "Using fallback template: $fallback_template"
        template="$fallback_template"
    fi

    echo_info "Creating configuration for host $hostname from template $template..."
    cp -r "$template" "$hostname"

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

function select_desktop_environment {
    echo_question "Select desktop environment:"
    echo "1) GNOME"
    echo "2) KDE"
    echo "3) None (skip)"

    while true; do
        read -r -p "$(echo_question "Enter your choice [1]: ")" choice
        choice="${choice:-1}"

        case "$choice" in
            1) desktop_env="gnome"; break ;;
            2) desktop_env="kde"; break ;;
            3) desktop_env=""; break ;;
            *) echo_error "Invalid choice. Please enter 1, 2 or 3." ;;
        esac
    done

    if [ -n "$desktop_env" ]; then
        echo_info "Selected desktop environment: $desktop_env"
    else
        echo_info "No desktop environment selected"
    fi
    declare -g desktop_env
}

function select_graphics_driver {
    echo_question "Select graphics driver:"
    echo "1) Intel"
    echo "2) NVIDIA"
    echo "3) NVIDIA + Intel (hybrid)"
    echo "4) None (skip)"

    while true; do
        read -r -p "$(echo_question "Enter your choice [1]: ")" choice
        choice="${choice:-1}"

        case "$choice" in
            1) graphics_driver="intel"; break ;;
            2) graphics_driver="nvidia"; break ;;
            3) graphics_driver="nvidia-intel"; break ;;
            4) graphics_driver=""; break ;;
            *) echo_error "Invalid choice. Please enter 1, 2, 3 or 4." ;;
        esac
    done

    if [ -n "$graphics_driver" ]; then
        echo_info "Selected graphics driver: $graphics_driver"
    else
        echo_info "No graphics driver selected"
    fi
    declare -g graphics_driver
}

function edit_config_files {
    local repo_dir="$HOME/.nix"
    local files_to_edit=()

    echo_info "Opening configuration files for editing..."

    # Common files for all templates
    local common_files=(
        "local-packages.nix"
        "../../home-manager/home-packages.nix"
        "../../home-manager/modules/git.nix"
    )

    # Template-specific files
    if [[ "$template" == "nixos" ]]; then
        files_to_edit=(
            "${common_files[@]}"
            "../../nixos/modules/base/default.nix"
            "../../nixos/modules/boot/default.nix"
            "../../nixos/modules/desktop/default.nix"
            "../../nixos/modules/graphics/default.nix"
        )
    else
        # Add template-specific configuration file
        files_to_edit+=("../../nixos/modules/${template}.nix")

        # Add desktop environment if selected
        select_desktop_environment
        if [ -n "$desktop_env" ]; then
            files_to_edit+=("../../nixos/modules/desktop/${desktop_env}.nix")
        fi

        # Add graphics driver if selected
        select_graphics_driver
        if [ -n "$graphics_driver" ]; then
            files_to_edit+=("../../nixos/modules/graphics/${graphics_driver}.nix")
        fi

        files_to_edit+=("${common_files[@]}")
    fi

    for file in "${files_to_edit[@]}"; do
        local full_path="$repo_dir/hosts/$hostname/$file"
        if [ -f "$full_path" ]; then
            nano "$full_path"
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
    choose_template
    setup_repository
    configure_host "$hostname" "$template"
    edit_flake
    edit_config_files
    run_zapret_check
    edit_zapret_config
    rebuild_system

    echo_info "Configuration complete!"
    echo_info "Please reboot the system."
    echo_info "After rebooting, run 'bash ./setup_after_reboot.sh' to complete the setup."
    echo_info "Note: Zsh setup is not required; skip this step to let home-manager handle it automatically."

    if ask_confirmation "Reboot the system now?"; then
        echo_info "Rebooting..."
        sudo reboot
    else
        echo_info "You can reboot later to apply all changes."
    fi
}

main "$@"
