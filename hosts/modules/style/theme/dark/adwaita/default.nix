{ pkgs, lib, ... }:
{
  qt = {
    enable = true;
    # platformTheme = "qt6ct";
    style = "adwaita-dark";
  };

  environment = {

    systemPackages = with pkgs; [
      gsettings-desktop-schemas
      gtk3
      adw-gtk3
      adwaita-icon-theme # Adwaita icon theme
      adwaita-qt6 # Adwaita Qt6 theme
      gnome-themes-extra # Extra GNOME themes
      hicolor-icon-theme # Fallback icon theme
    ];

    sessionVariables = {
      QT_STYLE_OVERRIDE = "adwaita-dark";
      QT_QPA_PLATFORMTHEME = "qt6ct";

      XDG_DATA_DIRS = with pkgs; [
        "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}"
        "${gtk3}/share"
        "${adwaita-icon-theme}/share"
        "${hicolor-icon-theme}/share"
        "/run/current-system/sw/share"
      ];

      GSETTINGS_SCHEMA_DIR =
        let
          schemas = pkgs.gsettings-desktop-schemas;
          gtk = pkgs.gtk3;
        in
        "${schemas}/share/gsettings-schemas/${schemas.name}/glib-2.0/schemas:${gtk}/share/gsettings-schemas/${gtk.name}/glib-2.0/schemas";
    };
  };

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
}
