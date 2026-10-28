{ lib }:
let
  dsp = lib.generators.mkLuaInline;
in
{
  # All keybinds — each element → hl.bind(keys, dispatcher, opts?)
  # Key format: "MOD1 + MOD2 + KEY" (each mod and the key joined with " + ")
  # opts: { locked = true; } for bindl, { repeating = true; } for binde,
  #       { repeating = true; locked = true; } for bindel, { mouse = true; } for bindm
  # Compositor dispatchers only: plain-command binds live in custom.keybinds
  # (home/astroreen/profiles/wm/keybinds, shell ones in profiles/wm/shell/<shell>/binds.nix).
  bind = [
    # --- Window management ---
    { _args = [ "SUPER + C" (dsp "hl.dsp.window.close()") ]; }
    { _args = [ "SUPER + M" (dsp "hl.dsp.exit()") ]; }

    # Focus and swap windows
    { _args = [ "SUPER + left" (dsp "hl.dsp.focus({ direction = \"left\" })") ]; }
    { _args = [ "SUPER + right" (dsp "hl.dsp.focus({ direction = \"right\" })") ]; }
    { _args = [ "SUPER + up" (dsp "hl.dsp.focus({ direction = \"up\" })") ]; }
    { _args = [ "SUPER + down" (dsp "hl.dsp.focus({ direction = \"down\" })") ]; }
    { _args = [ "SUPER + SHIFT + left" (dsp "hl.dsp.window.swap({ direction = \"left\" })") ]; }
    { _args = [ "SUPER + SHIFT + right" (dsp "hl.dsp.window.swap({ direction = \"right\" })") ]; }
    { _args = [ "SUPER + SHIFT + up" (dsp "hl.dsp.window.swap({ direction = \"up\" })") ]; }
    { _args = [ "SUPER + SHIFT + down" (dsp "hl.dsp.window.swap({ direction = \"down\" })") ]; }

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

    # --- Special workspace (toggled by the shell's SUPER + S) ---
    { _args = [ "CTRL + SUPER + up" (dsp "hl.dsp.window.move({ workspace = \"special:special\" })") ]; }
    { _args = [ "CTRL + SUPER + down" (dsp "hl.dsp.window.move({ workspace = \"e+0\" })") ]; }

    # --- Mouse binds (mouse = true) ---
    { _args = [ "SUPER + mouse:272" (dsp "hl.dsp.window.drag()") { mouse = true; } ]; }
    { _args = [ "SUPER + mouse:273" (dsp "hl.dsp.window.resize()") { mouse = true; } ]; }
    { _args = [ "SUPER + Z" (dsp "hl.dsp.window.drag()") { mouse = true; } ]; }
  ];
}
