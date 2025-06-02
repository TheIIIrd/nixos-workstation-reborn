{ pkgs, ... }: {
  home.packages = with pkgs; [
    adw-gtk3
    tela-circle-icon-theme
  ];

  qt = {
    enable = true;
    platformTheme.name = "kde6";
    style.name = "breeze";
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
