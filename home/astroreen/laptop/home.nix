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
      # Repo values win on every switch, so a setting synced from one host
      # (`sync-dux-config <host>`) reaches the others. Sync before switching
      # if you changed something in the dux UI, or it is reverted.
      overrideSettings = true;
      # Machine-bound keys only; the portable rest is in profiles/wm/shell/dux
      settings = lib.importJSON ./assets/dux-settings.json;
      session = lib.importJSON ./assets/dux-session.json;
      pluginSettings = lib.importJSON ./assets/dux-plugin-settings.json;
    };

    caelestia = {
      enable = false;
      settings = lib.mkDefault (
        builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json)
      );
    };
  };
}
