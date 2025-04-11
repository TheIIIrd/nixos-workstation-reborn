{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    easyeffects
    gparted
    # gpu-screen-recorder-gtk
    # gpu-screen-recorder
    inkscape
    # jetbrains.idea-community-bin
    # jetbrains.pycharm-community-bin
    kdePackages.kdenlive
    kdePackages.qtstyleplugin-kvantum
    krita
    # mcontrolcenter

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

    # Other
    kdePackages.qt6ct
    libsForQt5.qt5ct
  ];
}
