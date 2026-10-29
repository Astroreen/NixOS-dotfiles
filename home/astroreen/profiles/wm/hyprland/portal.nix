{ pkgs, inputs, ... }:
{
  # XDG desktop portals. The portal packages themselves (hyprland + gtk
  # fallback) are installed system-wide in hosts/astroreen/profiles/wm/hyprland.

  # Fix for Hyprland's xdg-desktop-portal
  systemd.user.services.xdg-desktop-portal-hyprland = {
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

  # xdg-desktop-portal-gtk dialogs (file chooser, ...) float centered
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(xdg-desktop-portal-gtk)$";
      size = "1400 800";
      center = true;
      float = true;
    }
  ];
}
