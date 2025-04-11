{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    kicad
    obs-studio
    obsidian
    onlyoffice-desktopeditors
    protonplus
    protontricks
    r2modman
    tenacity
    tor-browser
    ungoogled-chromium
    vesktop
    vscodium

    # CLI utils
    bc
    binwalk
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
