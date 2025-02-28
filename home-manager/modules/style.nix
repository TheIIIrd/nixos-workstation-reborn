{ pkgs, ... }: {
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-qt
    tela-circle-icon-theme
  ];

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style = {
      name = "adwaita-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      name = "Tela-circle-dark";
    };
  };
}
