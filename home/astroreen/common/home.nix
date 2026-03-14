{
  pkgs,
  osConfig,
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.custom.caelestia;
in
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
  systemd.user.sessionVariables = osConfig.home-manager.users.astroreen.home.sessionVariables;

  wayland.windowManager.hyprland = {
    # Hyprland settings
    settings = import ./hyprland/settings.nix;
    # Hyprland submaps (keybinds)
    submaps = import ./hyprland/binds.nix;
  };

}
