{
  global.settings = {
    # Regular binds
    bind = [
      "$mod, C, killactive," # Close active window

      # Window resizing
      "$mod, Minus, splitratio, -0.1"
      "$mod, Equal, splitratio, 0.1"

      # Window states
      "$mod, F, fullscreen, 0" # Fullscreen
      "CTRL $mod, Space, togglefloating" # Makes window float above others
      "$mod, P, pseudo" # Reserve space for full window, but enable resizе
      "$mod, J, togglesplit" # Make windows stack vertically/horizontally

      "ALT, Tab, cyclenext, activewindow"
      "$mod, Tab, cyclenext, activewindow"
      "$mod, Tab, bringactivetotop"

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
    ];

    # Mouse binds
    bindm = [
      "$mod, mouse:272, movewindow" # Left click + drag to move window
      "$mod, mouse:273, resizewindow" # Right click + drag to resize window
      "$mod, Z, movewindow" # Better for touchpad on laptops
    ];

    # Locked binds (media and system)
    bindl = [
      # Volume mute toggle
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      # "$mod SHIFT, M, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
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
  };
}
