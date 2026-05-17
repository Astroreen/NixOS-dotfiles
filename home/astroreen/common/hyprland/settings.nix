{
  # Activate global submap on every config reload
  exec = "hyprctl dispatch submap global";

  # Keyboard settings for hyprland
  input = {
    kb_layout = "us,ru,lt";
    kb_variant = ",phonetic,";
    kb_options = ""; # Layout switching handled by Hyprland binds (SHIFT+ALT+E/R/L)

    follow_mouse = 1;

    touchpad = {
      natural_scroll = true;
    };

    sensitivity = 0;
  };

  # Windows rules
  windowrule =
    [ 
      # Make all modal windows float (e.g. Popups)
      "match:modal true, float on"
      "match:class me.astroreen, float on" # For development, make all my programs float when ran
      "match:class ^(\s*)$, float on" # All windows without class should float (e.g. vivaldi notifications)

      "match:class ^(com.interversehq.qView)$, size 1400 800, center on, float on, content photo"
      "match:class ^(xdg-desktop-portal-gtk)$, size 1400 800, center on, float on"
      "match:class ^(localsend_app)$, size 1400 800, center on, float on"
      "match:class ^(Postman)$, size 1400 800, center on, float on"

      # Content managment
      "match:content 3, float on" # All games should float
      "match:content 1, float on" # All photo should float
      "match:content 2, fullscreen on" # All video should be opened with fullscreen
    ];

  env = [
    "QT_QPA_PLATFORMTHEME, qt6ct"
    "QUICKSHELL_ENABLE_PORTAL, 1"
  ];
}
