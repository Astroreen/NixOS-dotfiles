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
    "[workspace 4 silent] pear-desktop"
    "[workspace 5 silent] obsidian"
  ];

  # Windows rules
  windowrule = [
    # Fullscreen auto-started programs
    "fullscreen on, match:class ^(Vivaldi-stable)$"
    "fullscreen on, match:class ^(discord)$"
    "fullscreen on, match:class ^(vesktop)$"
    "fullscreen on, match:class ^(com.github.tc_ch.youtube_music)$"
    "fullscreen on, match:class ^(obsidian)$"

    # Always open Discord on workspace 3
    "workspace 3 silent, match:class ^(discord)$"
    "workspace 3 silent, match:class ^(vesktop)$"

    # Make all programs float by default
    "float on, match:class ^(.*)$"

    # Always center VSCode notifications
    "center on, match:class ^(Code)$"

    # qView floating with specific size
    "size 1400 800, match:class ^(com.interversehq.qView)$"
    "center on, match:class ^(com.interversehq.qView)$"

    # File Manager floating with specific size
    "size 1400 800, match:class ^(org.gnome.Nautilus)$"
    "center on, match:class ^(org.gnome.Nautilus)$"
    "size 1400 800, match:class ^(org.gnome.NautilusPreviewer)$"
    "center on, match:class ^(org.gnome.NautilusPreviewer)$"
    "size 1400 800, match:class ^(xdg-desktop-portal-gtk)$"
    "center on, match:class ^(xdg-desktop-portal-gtk)$"

    # LocalSend always floating with specific size
    "size 1400 800, match:class ^(localsend_app)$"
    "center on, match:class ^(localsend_app)$"

    # Postman always floating with specific size
    "size 1400 800, match:class ^(Postman)$"
    "center on, match:class ^(Postman)$"

    # Console kitty floating with specific size
    "size 1200 800, match:class ^(kitty)$"

    # KDE Connect daemon window
    "fullscreen_state 0 3, match:class ^(org.kde.kdeconnect.daemon)$"
    "size 100% 100%, match:class ^(org.kde.kdeconnect.daemon)$"
    "center on, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_blur on, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_anim on, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_dim on, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_focus on, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_shadow on, match:class ^(org.kde.kdeconnect.daemon)$"
    "rounding 0, match:class ^(org.kde.kdeconnect.daemon)$"
    "no_follow_mouse on, match:class ^(org.kde.kdeconnect.daemon)$"
    "border_size 0, match:class ^(org.kde.kdeconnect.daemon)$" # instead of "noborder" we will use "border_size 0"
    "rounding 0, match:class ^(org.kde.kdeconnect.daemon)$"
  ];
}
