{
    
    # Common binds
    bind = [
        "$mainMod, T, exec, $terminal"
        "$mainMod, E, exec, $fileManager"

        "$mainMod, 1, exec, $menu"
        "$mainMod, 2, exec, $code"
        "$mainMod, 3, exec, $browser"
        "$mainMod, 4, exec, $editor"

        "$mainMod, Q, killactive,"
        "$mainMod, M, exit,"

        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        "$mainMod SHIFT, V, togglefloating"
        "$mainMod SHIFT, P, pseudo, " # dwindle
        # "$mainMod, J, togglesplit, " # dwindle

        "$mainMod, mouse_down, movetoworkspace, e+1"
        "$mainMod, mouse_up, movetoworkspace, e-1"

        ", PRINT, exec, hyprshot -m region"
    ];

    # Mouse bindings (bindm)
    bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
    ];

    bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
    ];

    # Repeated bindings (binde)
    # ...

    bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
    ];
}