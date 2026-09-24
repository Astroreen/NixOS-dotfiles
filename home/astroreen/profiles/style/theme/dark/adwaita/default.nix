{ lib, pkgs, ... }:
{
  # Use dark mode for GNOME apps
  dconf.settings = with lib.gvariant; {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  # The HM profile merges icons from every installed package into
  # $out/share/icons/<theme>, but the merged directory ships no
  # icon-theme.cache. GTK4/libadwaita therefore re-walks it on every cold
  # start. Generate caches here, where $out is still writable (same approach
  # as the NixOS gtk.iconCache module; the cache format is GTK3/GTK4 shared).
  home.extraProfileCommands = ''
    if [ -d "$out/share/icons" ]; then
      find "$out"/share/icons -exec test -d {} ';' -mindepth 1 -maxdepth 1 -print0 | while read -d $'\0' themedir
      do
        # Materialise read-only symlinked theme dirs so they become writable.
        if [ ! -w "$themedir" -a -L "$themedir" -a ! -r "$themedir"/icon-theme.cache ]; then
          path=$(readlink -f "$themedir")
          rm "$themedir"
          mkdir -p "$themedir"
          ln -s "$path"/* "$themedir"/
        fi

        if [ -w "$themedir" ]; then
          rm -f "$themedir"/icon-theme.cache
          ${pkgs.buildPackages.gtk3.out}/bin/gtk-update-icon-cache --ignore-theme-index "$themedir"
        fi
      done
    fi
  '';

  gtk = {
    enable = true;
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
