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

function execute_with_confirmation {
    local description="$1"
    local command="$2"

    if ask_confirmation "$description"; then
        echo_info "Executing: $command"
        eval "$command"
        return $?
    fi
    return 0
}

function uncomment_gtk_settings {
    local style_file="$HOME/.nix/home-manager/modules/style.nix"

    if [[ ! -f "$style_file" ]]; then
        echo_error "Style.nix not found at $style_file"
        return 1
    fi

    echo_info "Uncommenting GTK settings in style.nix..."

    # Create backup before editing
    cp "$style_file" "${style_file}.bak"

    sed -i -e "s/^  # gtk = {/  gtk = {/" \
           -e "s/^  #   enable = true;/    enable = true;/" \
           -e "s/^  #   theme = {/    theme = {/" \
           -e "s/^  #     name = \"adw-gtk3-dark\";/      name = \"adw-gtk3-dark\";/" \
           -e "s/^  #   };/    };/" \
           -e "s/^  #   iconTheme = {/    iconTheme = {/" \
           -e "s/^  #     name = \"Tela-circle-dark\";/      name = \"Tela-circle-dark\";/" \
           -e "s/^  #   };/    };/" \
           -e "s/^  # };/  };/" \
           "$style_file"

    echo_info "GTK settings uncommented successfully."
}

function run_nh_operations {
    if command -v nh &>/dev/null; then
        if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
            if ask_confirmation "Uncomment GTK settings in style.nix for GNOME?"; then
                uncomment_gtk_settings
            fi
        fi

        execute_with_confirmation "Run nh home switch?" "nh home switch"
        execute_with_confirmation "Optimize nix store?" "nix store optimise"
    else
        echo_warn "nh command not found, skipping nh operations"
    fi
}

function setup_flatpak {
    if ! ask_confirmation "Configure Flatpak? (This will add Flathub repository)"; then
        echo_info "Skipping Flatpak setup."
        return 0
    fi

    # Check if flatpak is installed
    if ! command -v flatpak &>/dev/null; then
        echo_warn "Flatpak is not installed."
        return 1
    fi

    # Add Flathub repository
    echo_info "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    local themes=(
        "org.gtk.Gtk3theme.adw-gtk3"
        "org.gtk.Gtk3theme.adw-gtk3-dark"
    )

    if ask_confirmation "Install GTK themes for Flatpak apps?"; then
        for theme in "${themes[@]}"; do
            echo_info "Installing theme: $theme"
            flatpak install -y "$theme" || echo_warn "Failed to install theme $theme"
        done
    fi

    local apps=(
        "ch.tlaun.TL:TL - Minecraft Launcher"
        "com.github.tchx84.Flatseal:Flatseal - Flatpak Permission Manager"
        "com.heroicgameslauncher.hgl:Heroic Games Launcher"
        "page.codeberg.libre_menu_editor.LibreMenuEditor:Menu Editor"
    )

    for app in "${apps[@]}"; do
        IFS=':' read -r app_id app_name <<< "$app"

        if ask_confirmation "Install $app_name?"; then
            echo_info "Installing $app_name..."
            flatpak install -y flathub "$app_id" || echo_warn "Failed to install $app_name"

            if [[ "$app_id" == "ch.tlaun.TL" ]]; then
                if ask_confirmation "Set TL environment override?"; then
                    flatpak --user override ch.tlaun.TL --env=TL_BOOTSTRAP_OPTIONS="-Dtl.useForce"
                fi
            fi
        fi
    done
}

function setup_gnome_keybindings {
    if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
        if ask_confirmation "Set GNOME keyboard shortcut for input switching?"; then
            gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"
        fi
    fi
}

function setup_fonts {
    if ask_confirmation "Copy corefonts to ~/.local/share/fonts?"; then
        fonts_dir="$HOME/.local/share/fonts"
        mkdir -p "$fonts_dir"

        # Find corefonts in nix store
        local corefonts_path
        corefonts_path=$(find /nix/store -maxdepth 1 -name "*-corefonts-1" -type d | head -n 1)

        if [[ -n "$corefonts_path" ]]; then
            if cp -r --no-preserve=mode "$corefonts_path"/share/fonts/truetype/* "$fonts_dir"; then
                echo_info "Fonts copied successfully."
                fc-cache -f "$fonts_dir"
            else
                echo_error "Failed to copy fonts."
            fi
        else
            echo_warn "Corefonts not found in nix store."
        fi
    fi
}

function setup_folder_structure {
    local base_dir="$HOME/BitLab"

    if ask_confirmation "Create recommended folder structure in $base_dir?"; then
        # Define folder structure
        declare -A folders=(
            ["$base_dir/CreationLab/ArtStore"]="Art projects"
            ["$base_dir/CreationLab/CodeStore/ArcLab"]="Git projects"
            ["$base_dir/CreationLab/CodeStore/CppLab"]="C++ projects"
            ["$base_dir/CreationLab/CodeStore/CsLab"]="C# projects"
            ["$base_dir/CreationLab/CodeStore/PyLab"]="Python projects"
            ["$base_dir/CreationLab/CodeStore/RsLab"]="Rust projects"
            ["$base_dir/CreationLab/DataStore"]="Data storage"
            ["$base_dir/CreationLab/PcbStore"]="PCB designs"
            ["$base_dir/GameLab/HeroicLab/Prefixes/default"]="Heroic Games Launcher prefixes"
            ["$base_dir/VirtualLab/EngineLab"]="Virtualization disk images"
            ["$base_dir/VirtualLab/SysImages"]="System images"
            ["$base_dir/WorkBench"]="Workspace"
        )

        for folder in "${!folders[@]}"; do
            if [[ ! -d "$folder" ]]; then
                echo_info "Creating ${folders[$folder]}..."
                mkdir -p "$folder"
            fi
        done

        echo_info "Folder structure created."
    fi
}

function main {
    echo_info "Starting system setup..."

    run_nh_operations
    setup_flatpak
    setup_gnome_keybindings
    setup_fonts
    setup_folder_structure

    echo_info "Setup completed!"

    if ask_confirmation "Reboot the system now?"; then
        echo_info "Rebooting..."
        sudo reboot
    else
        echo_info "You can reboot later to apply all changes."
    fi
}

main "$@"
