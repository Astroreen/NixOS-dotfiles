{ lib, ... }:
{
  imports = [
    ../common/desktop # Graphical workstation layer
    ../profiles/power # Battery mode (Hyprland effects, services)
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix;

  custom = {
    # Dictation: hercules when reachable (always on battery, on AC within
    # 150 ms), else the local RTX 3060, started on demand and stopped after
    # 5 idle minutes so the dGPU can power off again.
    dictation = {
      mode = "auto";
      server.idleExitMinutes = 5;
    };

    # LocalSend only when opened from the launcher, not as an always-on server
    localsend.autostart = false;

    # dux lowers the refresh rate on battery only within the current
    # resolution, and the panel has no native 1080p modes (2560x1440 only), so
    # battery mode switches to a custom 60 Hz mode on battery instead.
    power.battery.hyprland.batteryMonitors = [
      {
        output = "eDP-1";
        mode = "1920x1080@60";
        position = "0x0";
        scale = "1";
      }
    ];

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
