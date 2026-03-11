{ lib, ... }:
{
  imports = [
    ../common/home.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland-settings.nix;

  custom.caelestia = {
    enable = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));
  };
}
