{ pkgs, ... }: {
  services.xserver = {
    enable = true;

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    xkb = {
      layout = "us";
      variant = "";
    };

    videoDrivers = [ "nvidia" ];
  };

  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-shell-extensions
    gnome-tour
    seahorse
    snapshot
    totem
  ];
}
