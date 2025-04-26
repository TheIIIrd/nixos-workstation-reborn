#!/bin/bash

set -euo pipefail

# Function to output messages
function echo_info {
    echo -e "\e[32m[INFO]\e[0m $1"
}

function echo_error {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Checking for nh
if command -v nh >/dev/null 2>&1; then
    echo_info "Starting nh..."
    # nh os switch --update
    nh home switch
    nix store optimise
else
    echo_info "nh is not installed. Skipping nh home switch."
fi

# Checking for Flatpak
if command -v flatpak >/dev/null 2>&1; then
    # Installing Flatpak and setting it up
    echo_info "Setting up Flatpak..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
    flatpak install -y flathub com.github.tchx84.Flatseal com.heroicgameslauncher.hgl page.codeberg.libre_menu_editor.LibreMenuEditor ch.tlaun.TL
    flatpak --user override ch.tlaun.TL --env=TL_BOOTSTRAP_OPTIONS="-Dtl.useForce"
    flatpak install -y flathub --system com.dec05eba.gpu_screen_recorder
else
    echo_info "Flatpak is not installed. Skipping Flatpak setup."
fi

# Checking if the standard environment is GNOME
desktop_file="$HOME/.nix/nixos/modules/desktop/default.nix"
if grep -q '^\s*./gnome.nix' "$desktop_file" && [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    echo_info "Setting up GNOME keybindings..."
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Alt>Shift_L']"
else
    echo_info "Standard environment is not GNOME. Skipping keybindings setup."
fi

# Copying corefonts
echo_info "Copying corefonts to the home directory..."

# Checking and creating the directory if it doesn't exist
fonts_dir="$HOME/.local/share/fonts"
if [ ! -d "$fonts_dir" ]; then
    echo_info "Creating directory $fonts_dir..."
    mkdir -p "$fonts_dir"
fi

# Copying the fonts
cp --no-preserve=mode /nix/store/*-corefonts-1/share/fonts/truetype/* "$fonts_dir"

echo_info "Setup completed! Please reboot the system for the changes to take effect."
