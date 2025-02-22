{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    fragments
    gnome-builder
    obs-studio
    obsidian
    protonplus
    protontricks
    ptyxis
    qucs-s
    r2modman
    tenacity
    tor-browser
    ungoogled-chromium
    vesktop
    vscodium

    # CLI utils
    bc
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
    ueberzugpp
    unzip
    zip

    # Coding stuff
    dotnet-sdk
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
    gnomeExtensions.quick-lang-switch
    gnomeExtensions.vitals

    # Fonts
    corefonts
    dejavu_fonts
    jetbrains-mono
    meslo-lgs-nf
    noto-fonts
    noto-fonts-lgc-plus
    texlivePackages.hebrew-fonts
    noto-fonts-emoji
    font-awesome
    powerline-fonts
    powerline-symbols

    # Other
    nix-prefetch-scripts
  ];
}
