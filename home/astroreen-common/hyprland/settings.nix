# Think of this file like of an attribute set of `wayland.windowManager.hyprland.settings`

let
  binds = import ./binds.nix;
in

binds
# Added binds to configuration
// {
  # Keyboard settings for hyprland
  input = {
    kb_layout = "us,ru";
    kb_variant = ",phonetic";
    kb_options = "grp:alt_shift_toggle"; # Alt + Shift to switch layouts

    follow_mouse = 1;

    touchpad = {
      natural_scroll = true;
    };

    sensitivity = 0;
  };

  exec-once = [
    # On start up enable apps on certain workspaces
    "[workspace 2 silent] vivaldi"
    "[workspace 3 silent] vesktop"
    "[workspace 4 silent] sleep 7 && spotify"
    "[workspace 5 silent] obsidian"
  ];

  # Windows rules
  windowrulev2 = [
    # Fullscreen auto-started programs
    "fullscreen,class:^(Vivaldi-stable)$"
    "fullscreen,class:^(discord)$"
    "fullscreen,class:^(vesktop)$"
    "fullscreen,class:^(spotify)$"
    "fullscreen,class:^(obsidian)$"

    # Always open Discord on workspace 3
    "workspace 3 silent,class:^(discord)$"
    "workspace 3 silent,class:^(vesktop)$"

    # Always center VSCode notifications
    "center,class:^(Code)$"

    # qView floating with specific size
    "float,class:^(com.interversehq.qView)$"
    "size 1400 800,class:^(com.interversehq.qView)$"
    "center,class:^(com.interversehq.qView)$"

    # File Manager floating with specific size
    "float,class:^(org.gnome.Nautilus)$"
    "size 1400 800,class:^(org.gnome.Nautilus)$"
    "center,class:^(org.gnome.Nautilus)$"
    "float,class:^(org.gnome.NautilusPreviewer)$"
    "size 1400 800,class:^(org.gnome.NautilusPreviewer)$"
    "center,class:^(org.gnome.NautilusPreviewer)$"
    "float,class:^(xdg-desktop-portal-gtk)$"
    "size 1400 800,class:^(xdg-desktop-portal-gtk)$"
    "center,class:^(xdg-desktop-portal-gtk)$"

    # LocalSend always floating with specific size
    "float,class:^(localsend_app)$"
    "size 1400 800,class:^(localsend_app)$"
    "center,class:^(localsend_app)$"

    # Postman always floating with specific size
    "float,class:^(Postman)$"
    "size 1400 800,class:^(Postman)$"
    "center,class:^(Postman)$"

    # Console kitty floating with specific size
    "float,class:^(kitty)$"
    "size 1200 800,class:^(kitty)$"

    # KDE Connect daemon window
    "fullscreenstate 0 3,class:^(org.kde.kdeconnect.daemon)$"
    "float,class:^(org.kde.kdeconnect.daemon)$"
    "size 100% 100%,class:^(org.kde.kdeconnect.daemon)$"
    "center,class:^(org.kde.kdeconnect.daemon)$"
    "noblur,class:^(org.kde.kdeconnect.daemon)$"
    "noanim,class:^(org.kde.kdeconnect.daemon)$"
    "noborder,class:^(org.kde.kdeconnect.daemon)$"
    "nodim,class:^(org.kde.kdeconnect.daemon)$"
    "nofocus,class:^(org.kde.kdeconnect.daemon)$"
    "noshadow,class:^(org.kde.kdeconnect.daemon)$"
    "norounding,class:^(org.kde.kdeconnect.daemon)$"
    "nofollowmouse,class:^(org.kde.kdeconnect.daemon)$"
    "bordersize 0,class:^(org.kde.kdeconnect.daemon)$"
    "rounding 0,class:^(org.kde.kdeconnect.daemon)$"
  ];
}
