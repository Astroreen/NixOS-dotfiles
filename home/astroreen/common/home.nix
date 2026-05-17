{
  inputs,
  config,
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
    settings = import ./hyprland/settings.nix;

    # Why is it not in binds.nix? Because these are my personal keybinds, and not general Hyprland ones
    submaps.global.settings.bind = [
      # Switch keyboard layout directly via hyprctl IPC
      "SHIFT ALT, E, exec, hyprctl switchxkblayout all 0" # English (us)
      "SHIFT ALT, R, exec, hyprctl switchxkblayout all 1" # Russian (ru)
      "SHIFT ALT, L, exec, hyprctl switchxkblayout all 2" # Lithuanian (lt)
    ];
  };
}
