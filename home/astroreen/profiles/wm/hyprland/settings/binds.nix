{ lib }:
let
  dsp = lib.generators.mkLuaInline;
in
{
  # All keybinds — each element → hl.bind(keys, dispatcher, opts?)
  # Key format: "MOD1 + MOD2 + KEY" (each mod and the key joined with " + ")
  # opts: { locked = true; } for bindl, { repeating = true; } for binde,
  #       { repeating = true; locked = true; } for bindel, { mouse = true; } for bindm
  bind = [
    # --- Window management ---
    { _args = [ "SUPER + C" (dsp "hl.dsp.window.close()") ]; }

    # Window resizing (dwindle splitratio — standalone dispatcher, not a layoutmsg)
    { _args = [ "SUPER + Minus" (dsp "hl.dsp.exec_cmd(\"hyprctl dispatch splitratio -0.1\")") ]; }
    { _args = [ "SUPER + Equal" (dsp "hl.dsp.exec_cmd(\"hyprctl dispatch splitratio 0.1\")") ]; }

    # Window states
    { _args = [ "SUPER + F" (dsp "hl.dsp.window.fullscreen()") ]; }
    { _args = [ "CTRL + SUPER + Space" (dsp "hl.dsp.window.float({ action = \"toggle\" })") ]; }
    { _args = [ "SUPER + P" (dsp "hl.dsp.window.pseudo()") ]; }
    { _args = [ "SUPER + J" (dsp "hl.dsp.layout(\"togglesplit\")") ]; }

    # Window cycling
    { _args = [ "ALT + Tab" (dsp "hl.dsp.window.cycle_next()") ]; }
    { _args = [ "SUPER + Tab" (dsp "hl.dsp.window.cycle_next()") ]; }
    { _args = [ "SUPER + Tab" (dsp "hl.dsp.window.bring_to_top()") ]; }

    # --- Workspace navigation ---
    { _args = [ "SUPER + 1" (dsp "hl.dsp.focus({ workspace = 1 })") ]; }
    { _args = [ "SUPER + 2" (dsp "hl.dsp.focus({ workspace = 2 })") ]; }
    { _args = [ "SUPER + 3" (dsp "hl.dsp.focus({ workspace = 3 })") ]; }
    { _args = [ "SUPER + 4" (dsp "hl.dsp.focus({ workspace = 4 })") ]; }
    { _args = [ "SUPER + 5" (dsp "hl.dsp.focus({ workspace = 5 })") ]; }
    { _args = [ "SUPER + 6" (dsp "hl.dsp.focus({ workspace = 6 })") ]; }
    { _args = [ "SUPER + 7" (dsp "hl.dsp.focus({ workspace = 7 })") ]; }
    { _args = [ "SUPER + 8" (dsp "hl.dsp.focus({ workspace = 8 })") ]; }
    { _args = [ "SUPER + 9" (dsp "hl.dsp.focus({ workspace = 9 })") ]; }
    { _args = [ "SUPER + 0" (dsp "hl.dsp.focus({ workspace = 10 })") ]; }

    # --- Move window to workspace ---
    { _args = [ "SUPER + SHIFT + 1" (dsp "hl.dsp.window.move({ workspace = 1 })") ]; }
    { _args = [ "SUPER + SHIFT + 2" (dsp "hl.dsp.window.move({ workspace = 2 })") ]; }
    { _args = [ "SUPER + SHIFT + 3" (dsp "hl.dsp.window.move({ workspace = 3 })") ]; }
    { _args = [ "SUPER + SHIFT + 4" (dsp "hl.dsp.window.move({ workspace = 4 })") ]; }
    { _args = [ "SUPER + SHIFT + 5" (dsp "hl.dsp.window.move({ workspace = 5 })") ]; }
    { _args = [ "SUPER + SHIFT + 6" (dsp "hl.dsp.window.move({ workspace = 6 })") ]; }
    { _args = [ "SUPER + SHIFT + 7" (dsp "hl.dsp.window.move({ workspace = 7 })") ]; }
    { _args = [ "SUPER + SHIFT + 8" (dsp "hl.dsp.window.move({ workspace = 8 })") ]; }
    { _args = [ "SUPER + SHIFT + 9" (dsp "hl.dsp.window.move({ workspace = 9 })") ]; }
    { _args = [ "SUPER + SHIFT + 0" (dsp "hl.dsp.window.move({ workspace = 10 })") ]; }

    # --- Mouse binds (mouse = true) ---
    { _args = [ "SUPER + mouse:272" (dsp "hl.dsp.window.drag()") { mouse = true; } ]; }
    { _args = [ "SUPER + mouse:273" (dsp "hl.dsp.window.resize()") { mouse = true; } ]; }
    { _args = [ "SUPER + Z" (dsp "hl.dsp.window.drag()") { mouse = true; } ]; }

    # --- Locked binds (locked = true) ---
    { _args = [ "XF86AudioMute" (dsp "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")") { locked = true; } ]; }

    # --- Repeat + locked binds (repeating = true; locked = true) ---
    { _args = [ "XF86AudioRaiseVolume" (dsp "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+\")") { repeating = true; locked = true; } ]; }
    { _args = [ "XF86AudioLowerVolume" (dsp "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-\")") { repeating = true; locked = true; } ]; }
    { _args = [ "XF86AudioMicMute" (dsp "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle\")") { repeating = true; locked = true; } ]; }
    { _args = [ "XF86MonBrightnessUp" (dsp "hl.dsp.exec_cmd(\"brightnessctl s 10%+\")") { repeating = true; locked = true; } ]; }
    { _args = [ "XF86MonBrightnessDown" (dsp "hl.dsp.exec_cmd(\"brightnessctl s 10%-\")") { repeating = true; locked = true; } ]; }
  ];
}
