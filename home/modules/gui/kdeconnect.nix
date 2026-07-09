{ pkgs, ... }:
{
  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };

  wayland.windowManager.hyprland.settings.window_rule = [
    # KDE Connect daemon window
    {
      match.class = "^(org.kde.kdeconnect.daemon)$";
      fullscreen_state = "0 3";
      size = "100% 100%";
      center = true;
      no_blur = true;
      no_anim = true;
      no_dim = true;
      no_focus = true;
      no_shadow = true;
      no_follow_mouse = true;
      rounding = 0;
      border_size = 0;
    }
  ];
}
