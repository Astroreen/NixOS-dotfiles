{ lib, ... }:
{
  imports = [
    ../common/base.nix # Headless home shared by all hosts
    ../common/desktop.nix # Graphical workstation layer
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix;

  custom.caelestia = {
    enable = true;
    enableDefaultKeyboardBinds = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));
  };
}
