{ pkgs, ... }: {
  services.displayManager = {
    defaultSession = "plasma";
    sddm.enable = true;
    sddm.wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;
  programs.dconf.enable = true;

  environment.systemPackages = (with pkgs; [
    okteta
    vlc
  ]) ++ (with pkgs.kdePackages; [
    filelight
    kcalc
    kcolorchooser
    kompare
    ktorrent
    partitionmanager
    yakuake
  ]);
}
