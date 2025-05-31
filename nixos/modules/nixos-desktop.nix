{
  imports = [
    # Configs in each category are sorted alphabetically

    # Core utilities
    ./base/amnezia.nix
    ./base/audio.nix
    # ./base/bluetooth.nix
    ./base/env.nix
    ./base/firefox.nix
    ./base/firejail.nix
    ./base/flatpak.nix
    ./base/fwupd.nix
    ./base/home-manager.nix
    ./base/kernel.nix
    ./base/locale.nix
    ./base/mime.nix
    ./base/net.nix
    ./base/nh.nix
    ./base/nix.nix
    ./base/obs.nix
    ./base/printing.nix
    ./base/steam.nix
    ./base/timezone.nix
    ./base/trim.nix
    ./base/user.nix
    ./base/virt-manager.nix
    # ./base/yggdrasil.nix
    ./base/zapret.nix
    ./base/zerotierone.nix
    ./base/zram.nix

    # Bootloaders
    ./boot/systemd-boot.nix

    # Desktop environments
    ./desktop/kde.nix
    ./desktop/xserver.nix

    # GPUs
    ./graphics/nvidia.nix
  ];
}
