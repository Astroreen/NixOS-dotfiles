{
  inputs,
  config,
  lib,
  ...
}:
{

  imports = [
    ./hyprland/caelestia # Custom Caelestia shell module

    # Style
    ../../modules/style/cursor/breeze # Breeze cursor style
    ../../modules/style/theme/dark/adwaita # Adwaita dark theme

    # Apps
    ../../common-apps.nix

    # Windows manager (wm)
    ../../modules/wm/hyprland # Hyprland window manager
    ../../modules/wm/hyprland/caelestia # Caelestia shell
    inputs.caelestia-shell.homeManagerModules.default # Caelestia shell module
  ];

  # Wayland, X, etc. support for session vars
  systemd.user.sessionVariables = config.home.sessionVariables;

  wayland.windowManager.hyprland = {
    # Hyprland settings
    settings = lib.mkMerge [
      (import ./hyprland/settings.nix { inherit lib; })
      {
        # Why is it not in binds.nix? Because these are my personal keybinds, and not general Hyprland ones
        bind =
          let
            dsp = lua: lib.generators.mkLuaInline lua;
          in
          [
            # Switch keyboard layout directly via hyprctl IPC
            { _args = [ "SHIFT + ALT + E" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 0\")") ]; } # English (us)
            { _args = [ "SHIFT + ALT + R" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 1\")") ]; } # Russian (ru)
            { _args = [ "SHIFT + ALT + L" (dsp "hl.dsp.exec_cmd(\"hyprctl switchxkblayout all 2\")") ]; } # Lithuanian (lt)
          ];
      }
    ];
  };
}
