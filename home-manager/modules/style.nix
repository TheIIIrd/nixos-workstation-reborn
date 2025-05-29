{ pkgs, ... }: {
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-qt
    tela-circle-icon-theme
  ];

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # gtk = {
  #   enable = true;
  #   theme = {
  #     name = "adw-gtk3-dark";
  #   };
  #   iconTheme = {
  #     name = "Tela-circle-dark";
  #   };
  # };
}
