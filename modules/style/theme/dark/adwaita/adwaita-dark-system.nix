{ pkgs, lib, ... }:
{
  qt = {
    enable = true;
    # platformTheme = "qt6ct";
    style = "adwaita-dark";
  };

  environment.sessionVariables.QT_STYLE_OVERRIDE = "adwaita-dark";
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "qt6ct";

  # required for some apps to follow dark mode
  programs.dconf.profiles.user.databases = [
    {
      settings = with lib.gvariant; {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark"; # for GTK4 apps
          gtk-theme = "adw-gtk3-dark"; # for GTK3 apps
        };
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    adw-gtk3
    adwaita-icon-theme # Adwaita icon theme
    adwaita-qt6 # Adwaita Qt6 theme
    gnome-themes-extra # Extra GNOME themes
  ];
}
