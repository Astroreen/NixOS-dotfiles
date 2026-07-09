{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  systemd.user = {
    enable = true;
    services = {
      # Fix for Hyprland's xdg-desktop-portal
      xdg-desktop-portal-hyprland = {
        Service = {
          Environment = [
            "WAYLAND_DISPLAY=wayland-1"
            "XDG_CURRENT_DESKTOP=Hyprland"
            "XDG_SESSION_TYPE=wayland"
          ];
          ExecStart = [
            ""
            "${
              inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
            }/libexec/xdg-desktop-portal-hyprland"
          ];
          Restart = "on-failure";
          RestartSec = "3s";
        };

        Unit = {
          ConditionEnvironment = ""; # clear previous Condition
          After = [ "hyprland-session.target" ];
        };
      };
    };
  };

  home.packages = with pkgs; [
    hyprpicker # Color picker for Hyprland
    grim # Screenshot tool for wayland
    uwsm # Window manager for wayland
    pipewire # PipeWire media server
    lm_sensors # Hardware sensors
    inotify-tools # Inotify tools
  ];

  # Wayland settings
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    settings = lib.mkMerge [
      (import ./settings { inherit lib pkgs; })
      (import ./settings/binds.nix { inherit lib; })
    ];
  };
}
