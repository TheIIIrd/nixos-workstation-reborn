{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    blockbench
    inkscape
    kicad
    krita
    obsidian
    onlyoffice-desktopeditors
    # prismlauncher
    protonplus
    protontricks
    r2modman
    # telegram-desktop
    tenacity
    tor-browser
    ungoogled-chromium
    vesktop
    vscodium

    # CLI utils
    binwalk
    fastfetch
    ffmpeg
    file
    fzf
    git-graph
    mediainfo
    ripgrep
    shellcheck
    silicon
    texliveTeTeX
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
    jetbrains-mono
    meslo-lgs-nf
    noto-fonts
    noto-fonts-lgc-plus
    noto-fonts-emoji
    font-awesome
    powerline-fonts
    powerline-symbols

    # Other
    nix-prefetch-scripts
  ];
}
