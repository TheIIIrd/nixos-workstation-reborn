{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    fragments
    obs-studio
    obsidian
    onlyoffice-bin_latest
    protonplus
    protontricks
    ptyxis
    tenacity
    tor-browser
    ungoogled-chromium
    vesktop
    vscodium

    # CLI utils
    bat
    fastfetch
    ffmpeg
    file
    fzf
    git
    git-graph
    lazygit
    mediainfo
    ranger
    ripgrep
    silicon
    tldr
    tree
    unzip
    zip

    # Coding stuff
    dotnet-sdk_8
    meson
    mono
    python312
    python312Packages.black
    python312Packages.matplotlib
    python312Packages.numpy
    python312Packages.pip

    # Extensions
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.just-perfection

    # Customization
    adw-gtk3
    tela-circle-icon-theme

    # Fonts
    corefonts
    dejavu_fonts
    jetbrains-mono
    meslo-lgs-nf
    noto-fonts
    noto-fonts-emoji
    font-awesome
    powerline-fonts
    powerline-symbols

    # Other
    nix-prefetch-scripts
  ];
}
