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

function setup_flatpak {
    if ! command -v flatpak >/dev/null 2>&1; then
        echo_warn "Flatpak is not installed. Skipping Flatpak setup."
        return 1
    fi

    if ! ask_confirmation "Configure Flatpak?"; then
        return 0
    fi

    echo_info "Adding Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        echo_error "Failed to add Flathub repository!"
        return 1
    fi

    flatpak install -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark 2>/dev/null || echo_warn "Failed to install GTK themes"

    local apps_to_install=(
        "ch.tlaun.TL"
        "com.github.tchx84.Flatseal"
        "com.heroicgameslauncher.hgl"
        "page.codeberg.libre_menu_editor.LibreMenuEditor"
    )

    for app in "${apps_to_install[@]}"; do
        if ask_confirmation "Install $app from Flathub?"; then
            echo_info "Installing $app..."
            flatpak install -y flathub "$app" || echo_warn "Failed to install $app"
        fi
    done

    if flatpak list --app | grep -q "ch.tlaun.TL"; then
        if ask_confirmation "Set TL environment override?"; then
            flatpak --user override ch.tlaun.TL --env=TL_BOOTSTRAP_OPTIONS="-Dtl.useForce"
        fi
    fi
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
        [[ ! -d "$fonts_dir" ]] && mkdir -p "$fonts_dir"

        if cp --no-preserve=mode /nix/store/*-corefonts-1/share/fonts/truetype/* "$fonts_dir" 2>/dev/null; then
            echo_info "Fonts copied successfully."
        else
            echo_error "Failed to copy fonts."
        fi
    fi
}

function setup_folder_structure {
    if ask_confirmation "Create recommended folder structure in ~/BitLab?"; then
        mkdir -p ~/BitLab/CreationLab/{ArtStore,CodeStore/{ArcLab,CppLab,CsLab,PyLab,RsLab},DataStore,PcbStore} \
                 ~/BitLab/GameLab/HeroicLab/Prefixes/default \
                 ~/BitLab/VirtualLab/{EngineLab,SysImages} \
                 ~/BitLab/WorkBench
        echo_info "Folder structure created."
    fi
}

function main {
    echo_info "Starting system setup..."

    # nh setup
    if command -v nh >/dev/null 2>&1; then
        if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
            if ask_confirmation "Uncomment GTK settings in style.nix for GNOME?"; then
                uncomment_gtk_settings
            fi
        fi

        execute_with_confirmation "Run nh home switch?" "nh home switch"
        execute_with_confirmation "Optimize nix store?" "nix store optimise"
    fi

    setup_flatpak
    setup_gnome_keybindings
    setup_fonts
    setup_folder_structure

    echo_info "Setup completed!"

    if ask_confirmation "Reboot the system now?"; then
        echo_info "Rebooting..."
        sudo reboot
    fi
}

main "$@"
