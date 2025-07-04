{ pkgs, ... }: {
  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
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

  environment.systemPackages = (with pkgs; [
    # cambalache
    clapper
    dconf-editor
    eyedropper
    fragments
    # gnome-builder
    gnome-tweaks
    mission-center
    ptyxis
    rnote
  ]) ++ (with pkgs.gnomeExtensions; [
    # accent-directories
    appindicator
    # arcmenu
    # blur-my-shell
    # burn-my-windows
    # caffeine
    clipboard-indicator
    # compiz-windows-effect
    # dash-to-panel
    just-perfection
    # vitals
  ]);
}
