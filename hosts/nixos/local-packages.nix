{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Desktop apps
    amberol
    clapper
    dconf-editor
    easyeffects
    gparted
    # gpu-screen-recorder
    # gpu-screen-recorder-gtk
    gnome-tweaks
    inkscape
    # jetbrains.idea-community-bin
    # jetbrains.pycharm-community-bin
    kdePackages.kdenlive
    krita
    # mcontrolcenter
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
