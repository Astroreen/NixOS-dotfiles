{ pkgs, config, lib, ... }:
{
  # Use dark mode for GNOME apps
  dconf.settings = with lib.gvariant; {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-decoration-layout = "menu:";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;

    # theme = {
    #   name = "Adwaita-dark";
    #   package = pkgs.gnome-themes-extra;
    # };
  };

  # Force GTK3 to use dark theme settings
  # xdg.configFile."gtk-3.0/settings.ini".text = ''
  #   [Settings]
  #   gtk-theme-name=Adwaita-dark
  #   gtk-application-prefer-dark-theme=1
  # '';

  # xdg.configFile = {
  #   "gtk-4.0/assets".source =
  #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
  #   "gtk-4.0/gtk.css".source =
  #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
  #   "gtk-4.0/gtk-dark.css".source =
  #     "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  # };
}
