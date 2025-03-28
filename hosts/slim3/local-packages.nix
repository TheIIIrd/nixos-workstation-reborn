{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Desktop apps
    amberol
    # amnezia-vpn
    clapper
    dconf-editor
    easyeffects
    gparted
    gnome-tweaks
    inkscape
    # jetbrains.idea-community-bin
    # jetbrains.pycharm-community-bin
    kdePackages.kdenlive
    krita
    mission-center

    # CLI utils
    aria2
    bind
    curl
    htop
    ipset
    lshw
    nmap
    radare2
    wget

    # Coding stuff
    android-tools
    cargo
    clang
    clang-tools
    cmake
    gcc
    gnumake
    ninja
    rustc
    zulu
  ];
}
