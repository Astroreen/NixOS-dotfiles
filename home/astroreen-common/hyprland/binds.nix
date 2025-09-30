{
  # Execute submap command and set to global
  exec = "hyprctl dispatch submap global";
  submap = "global";

  # Regular binds
  bind = [
    # Original app binds
    "$mod, T, exec, [float; size 1200 800] app2unit -- kitty" # Terminal
    "$mod, E, exec, [float; size 1400 800] app2unit -- nautilus" # File manager
    "$mod, Q, global, caelestia:launcher" # Menu/Launcher
    "$mod, C, killactive," # Close active window

    # Window resizing
    "$mod, Minus, splitratio, -0.1"
    "$mod, Equal, splitratio, 0.1"

    # Window states
    "$mod, F, fullscreen, 0" # Fullscreen
    "$mod ALT, Space, togglefloating" # Makes window float above others
    "$mod, P, pseudo" # Reserve space for full window, but enable resizе
    "$mod, J, togglesplit" # Make windows stack vertically/horizontally

    # Caelestia utilities
    "$mod, V, exec, pkill fuzzel || caelestia clipboard" # Clipboard menu
    "$mod ALT, V, exec, pkill fuzzel || caelestia clipboard -d" # Delete from history
    "$mod, Period, exec, pkill fuzzel || caelestia emoji -p" # Emoji picker
    "CTRL $mod SHIFT, R, exec, systemctl --user restart caelestia" # Kill/restart Caelestia shell
    ", PRINT, global, caelestia:screenshotFreeze" # Screenshots (enhanced from original)
    "$mod SHIFT, C, exec, hyprpicker -a" # Color picker (just like from powertoys on windows)

    # Caelestia shell integration
    "$mod, K, global, caelestia:showall"
    "$mod, L, global, caelestia:lock"
    "$mod SHIFT, L, exec, systemctl suspend-then-hibernate"
    "CTRL ALT, Delete, global, caelestia:session"
    "$mod, M, exit,"

    # Workspace navigation (original)
    "$mod, 1, workspace, 1"
    "$mod, 2, workspace, 2"
    "$mod, 3, workspace, 3"
    "$mod, 4, workspace, 4"
    "$mod, 5, workspace, 5"
    "$mod, 6, workspace, 6"
    "$mod, 7, workspace, 7"
    "$mod, 8, workspace, 8"
    "$mod, 9, workspace, 9"
    "$mod, 0, workspace, 10"

    # Move to workspace (original)
    "$mod SHIFT, 1, movetoworkspace, 1"
    "$mod SHIFT, 2, movetoworkspace, 2"
    "$mod SHIFT, 3, movetoworkspace, 3"
    "$mod SHIFT, 4, movetoworkspace, 4"
    "$mod SHIFT, 5, movetoworkspace, 5"
    "$mod SHIFT, 6, movetoworkspace, 6"
    "$mod SHIFT, 7, movetoworkspace, 7"
    "$mod SHIFT, 8, movetoworkspace, 8"
    "$mod SHIFT, 9, movetoworkspace, 9"
    "$mod SHIFT, 0, movetoworkspace, 10"

    # Workspace mouse navigation (enhanced)
    "$mod, mouse_down, workspace, -1"
    "$mod, mouse_up, workspace, +1"
    "$mod SHIFT, mouse_down, movetoworkspace, -1"
    "$mod SHIFT, mouse_up, movetoworkspace, +1"
    "CTRL $mod, mouse_down, workspace, -10"
    "CTRL $mod, mouse_up, workspace, +10"
    "CTRL $mod SHIFT, mouse_down, movetoworkspace, -10"
    "CTRL $mod SHIFT, mouse_up, movetoworkspace, +10"

    # Special workspaces (from Caelestia)
    "$mod, S, exec, caelestia toggle specialws"
    "CTRL $mod SHIFT, up, movetoworkspace, special:special"
    "CTRL $mod SHIFT, down, movetoworkspace, e+0"

    # Window positioning (from Caelestia)
    # "CTRL $mod, Backslash, centerwindow, 1"
    # "CTRL $mod ALT, Backslash, resizeactive, exact 55% 70%"
    # "$mod ALT, Backslash, exec, caelestia pip" # Picture-in-picture mode

    # Window groups (from Caelestia)
    "ALT, Tab, cyclenext, activewindow"
    "CTRL ALT, Tab, changegroupactive, f"
    "$mod, Comma, togglegroup"
    "$mod SHIFT, Comma, lockactivegroup, toggle"

    "$mod, left, movefocus, l"
    "$mod, right, movefocus, r"
    "$mod, up, movefocus, u"
    "$mod, down, movefocus, d"
    "$mod, Tab, cyclenext"
    "$mod, Tab, bringactivetotop"

    # Enhanced window movement from Caelestia
    "$mod SHIFT, left, movewindow, l"
    "$mod SHIFT, right, movewindow, r"
    "$mod SHIFT, up, movewindow, u"
    "$mod SHIFT, down, movewindow, d"
  ];

  bindin = [
    # "$mod, catchall, global, caelestia:launcherInterrupt"
    "$mod, mouse:272, global, caelestia:launcherInterrupt"
    "$mod, mouse:273, global, caelestia:launcherInterrupt"
    "$mod, mouse:274, global, caelestia:launcherInterrupt"
    "$mod, mouse:275, global, caelestia:launcherInterrupt"
    "$mod, mouse:276, global, caelestia:launcherInterrupt"
    "$mod, mouse:277, global, caelestia:launcherInterrupt"
    "$mod, mouse_up, global, caelestia:launcherInterrupt"
    "$mod, mouse_down, global, caelestia:launcherInterrupt"
  ];

  # Repeated binds
  binde = [
    "CTRL $mod, left, workspace, -1"
    "CTRL $mod, right, workspace, +1"
    "CTRL $mod SHIFT, right, movetoworkspace, +1"
    "CTRL $mod SHIFT, left, movetoworkspace, -1"
    "$mod, Page_Up, workspace, -1"
    "$mod, Page_Down, workspace, +1"
    "$mod SHIFT, Page_Up, movetoworkspace, -1"
    "$mod SHIFT, Page_Down, movetoworkspace, +1"
  ];

  # Mouse binds
  bindm = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
    "$mod, Z, movewindow" # Better for touchpad on laptops
  ];

  # Locked binds (media and system)
  bindl = [
    # Media controls (original + Caelestia enhancements)
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioPause, exec, playerctl play-pause"
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioStop, global, caelestia:mediaStop"

    # Enhanced media with Caelestia
    "CTRL $mod, Space, global, caelestia:mediaToggle"
    "CTRL $mod, Equal, global, caelestia:mediaNext"
    "CTRL $mod, Minus, global, caelestia:mediaPrev"

    # Brightness
    ", XF86MonBrightnessUp, global, caelestia:brightnessUp"
    ", XF86MonBrightnessDown, global, caelestia:brightnessDown"

    # Volume mute toggle
    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    # "$mod SHIFT, M, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

    # Notifications
    "CTRL ALT, C, global, caelestia:clearNotifs"

    # Lock restore
    "$mod ALT, L, exec, caelestia shell -d"
    "$mod ALT, L, global, caelestia:lock"

    # Test notification
    "$mod ALT, f12, exec, notify-send -u low -i dialog-information-symbolic 'Test notification' \"Here's a really long message to test truncation and wrapping\\nYou can middle click or flick this notification to dismiss it!\" -a 'Shell' -A \"Test1=I got it!\" -A \"Test2=Another action\""
  ];

  # Repeated + locked binds (volume and brightness)
  bindel = [
    ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"
    ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
    ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
    ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
  ];

  # For repeated + locked volume (alternative from Caelestia style)
  bindle = [
    ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"
    ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"
  ];
}
