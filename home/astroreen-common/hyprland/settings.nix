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
    kb_options = "grp:win_space_toggle,grp:alt_shift_toggle"; # Win + Space to switch layouts

    follow_mouse = 1;

    touchpad = {
      natural_scroll = true;
    };

    sensitivity = 0;
  };

  exec-once = [
    # On start up enable apps on certain workspaces
    "[workspace 2 silent] vivaldi"
    "[workspace 3 silent] discord"
    "[workspace 4 silent] spotify"
    "[workspace 5 silent] obsidian"
  ];

  # Windows rules
  windowrulev2 = [
    # Fullscreen auto-started programs
    "fullscreen,class:^(Vivaldi-stable)$"
    "fullscreen,class:^(discord)$"
    "fullscreen,class:^(spotify)$"
    "fullscreen,class:^(obsidian)$"

    # Always open Discord on workspace 3
    "workspace 3 silent,class:^(discord)$"

    # Always center VSCode notifications
    "center,class:^(Code)$"

    # qView floating with specific size
    "float,class:^(com.interversehq.qView)$"
    "size 1400 800,class:^(com.interversehq.qView)$"
    "center,class:^(com.interversehq.qView)$"

    # Nautilus floating with specific size
    "float,class:^(org.gnome.Nautilus)$"
    "size 1400 800,class:^(org.gnome.Nautilus)$"
    "center,class:^(org.gnome.Nautilus)$"

    # LocalSend always floating with specific size
    "float,class:^(localsend_app)$"
    "size 1400 800,class:^(localsend_app)$"
    "center,class:^(localsend_app)$"

    # Postman always floating with specific size
    "float,class:^(Postman)$"
    "size 1400 800,class:^(Postman)$"
    "center,class:^(Postman)$"
  ];
}
