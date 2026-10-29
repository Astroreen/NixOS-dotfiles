{ lib, ... }:
{
  imports = [
    ../common/desktop # Graphical workstation layer
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix;

  custom = {
    dux = {
      enable = true;
      overrideSettings = false;
      settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/dux-settings.json));
    };

    caelestia = {
      enable = false;
      settings = lib.mkDefault (
        builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json)
      );
    };
  };
}
