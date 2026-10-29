{ lib, ... }:
{
  imports = [
    ../common/desktop # Graphical workstation layer
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix;

  custom.caelestia = {
    enable = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));
  };

  # Ready for the switch to dux (enable it and disable caelestia above):
  # battery-aware idle, suspend-then-hibernate on battery
  custom.dux.settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/dux-settings.json));
}
