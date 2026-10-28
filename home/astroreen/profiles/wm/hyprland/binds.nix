{ lib, ... }:
let
  # Every field mkDefault, so a host overrides it without lib.mkForce.
  defaults = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault));

  directions = [
    "left"
    "right"
    "up"
    "down"
  ];
  # focusLeft, swapRight, ...
  perDirection =
    prefix: mkBind:
    lib.listToAttrs (
      map (
        dir:
        lib.nameValuePair "${prefix}${lib.toUpper (lib.substring 0 1 dir)}${lib.substring 1 (-1) dir}" (
          mkBind dir
        )
      ) directions
    );

  # SUPER + 1..9 -> workspaces 1..9, SUPER + 0 -> workspace 10
  workspaces = lib.genList (i: i + 1) 10;
  keyOf = ws: toString (lib.mod ws 10);
  perWorkspace =
    prefix: mkBind:
    lib.listToAttrs (map (ws: lib.nameValuePair "${prefix}${toString ws}" (mkBind ws)) workspaces);
in
{
  # Compositor dispatchers (Hyprland only, `hyprland.dispatch`). Plain-command
  # binds live in ../keybinds, shell actions in ../shell/<shell>/binds.nix.
  imports = [
    ../../../../modules/wm/keybinds # custom.keybinds
  ];

  custom.keybinds.binds = defaults (
    {
      # --- Window management ---
      closeWindow = {
        key = "SUPER + C";
        hyprland.dispatch = "hl.dsp.window.close()";
      };
      exit = {
        key = "SUPER + M";
        hyprland.dispatch = "hl.dsp.exit()";
      };

      # Window resizing (dwindle split ratio, a layout message)
      splitShrink = {
        key = "SUPER + Minus";
        hyprland.dispatch = ''hl.dsp.layout("splitratio -0.1")'';
      };
      splitGrow = {
        key = "SUPER + Equal";
        hyprland.dispatch = ''hl.dsp.layout("splitratio 0.1")'';
      };

      # Window states
      fullscreen = {
        key = "SUPER + F";
        hyprland.dispatch = "hl.dsp.window.fullscreen()";
      };
      toggleFloat = {
        key = "CTRL + SUPER + Space";
        hyprland.dispatch = ''hl.dsp.window.float({ action = "toggle" })'';
      };
      pseudo = {
        key = "SUPER + P";
        hyprland.dispatch = "hl.dsp.window.pseudo()";
      };
      toggleSplit = {
        key = "SUPER + J";
        hyprland.dispatch = ''hl.dsp.layout("togglesplit")'';
      };

      # Window cycling (SUPER + Tab: next window, raised to the top)
      cycleWindowsAlt = {
        key = "ALT + Tab";
        hyprland.dispatch = "hl.dsp.window.cycle_next()";
      };
      cycleWindows = {
        key = "SUPER + Tab";
        hyprland.dispatch = "hl.dsp.window.cycle_next()";
      };
      cycleWindowsRaise = {
        key = "SUPER + Tab";
        hyprland.dispatch = "hl.dsp.window.bring_to_top()";
      };

      # Special workspace (toggled by the shell's SUPER + S)
      moveToSpecial = {
        key = "CTRL + SUPER + up";
        hyprland.dispatch = ''hl.dsp.window.move({ workspace = "special:special" })'';
      };
      moveFromSpecial = {
        key = "CTRL + SUPER + down";
        hyprland.dispatch = ''hl.dsp.window.move({ workspace = "e+0" })'';
      };

      # Mouse: SUPER + LMB drags, SUPER + RMB resizes, SUPER + Z drags too
      dragWindow = {
        key = "SUPER + mouse:272";
        hyprland = {
          dispatch = "hl.dsp.window.drag()";
          flags.mouse = true;
        };
      };
      resizeWindow = {
        key = "SUPER + mouse:273";
        hyprland = {
          dispatch = "hl.dsp.window.resize()";
          flags.mouse = true;
        };
      };
      dragWindowKey = {
        key = "SUPER + Z";
        hyprland = {
          dispatch = "hl.dsp.window.drag()";
          flags.mouse = true;
        };
      };
    }
    # focusLeft..focusDown, swapLeft..swapDown
    // perDirection "focus" (dir: {
      key = "SUPER + ${dir}";
      hyprland.dispatch = ''hl.dsp.focus({ direction = "${dir}" })'';
    })
    // perDirection "swap" (dir: {
      key = "SUPER + SHIFT + ${dir}";
      hyprland.dispatch = ''hl.dsp.window.swap({ direction = "${dir}" })'';
    })
    # workspace1..workspace10, moveToWorkspace1..moveToWorkspace10
    // perWorkspace "workspace" (ws: {
      key = "SUPER + ${keyOf ws}";
      hyprland.dispatch = "hl.dsp.focus({ workspace = ${toString ws} })";
    })
    // perWorkspace "moveToWorkspace" (ws: {
      key = "SUPER + SHIFT + ${keyOf ws}";
      hyprland.dispatch = "hl.dsp.window.move({ workspace = ${toString ws} })";
    })
  );
}
