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
    "match:class vivaldi, fullscreen on, workspace 2 silent"
    "match:class discord|vesktop, fullscreen on, workspace 3 silent"
    "match:class youtube_music|spotify, fullscreen on, workspace 4 silent"
    "match:class ^(obsidian)$, workspace 5 silent"

    # Make all modal windows float (e.g. Popups)
    "match:modal true, float on"
    "match:class me.astroreen, float on" # For development, make all my programs float when ran 

    "match:class ^(Code)$, center on, float on" # Always center VSCode and it's notifications
    "match:class ^(com.interversehq.qView)$, size 1400 800, center on, float on, content photo"
    "match:class ^org.gnome.Nautilus, size 1400 800, center on, float on"
    "match:class ^(xdg-desktop-portal-gtk)$, size 1400 800, center on, float on"
    "match:class ^(localsend_app)$, size 1400 800, center on, float on"
    "match:class ^(Postman)$, size 1400 800, center on, float on"

    "match:class ^(kitty)$, size 1200 800, float on, center on"

    # KDE Connect daemon window
    "match:class ^(org.kde.kdeconnect.daemon)$, fullscreen_state 0 3, size 100% 100%, center on, no_blur on, no_anim on, no_dim on, no_focus on, no_shadow on, rounding 0, no_follow_mouse on, border_size 0, rounding 0"

    # Content managment
    "match:content 3, float on" # All games should float
    "match:content 1, float on" # All photo should float
    "match:content 2, fullscreen on" # All video should be opened with fullscreen
  ];
}
