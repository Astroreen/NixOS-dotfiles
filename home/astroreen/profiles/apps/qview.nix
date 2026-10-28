{ pkgs, ... }:
{
  # qView: minimal image viewer
  home.packages = [ pkgs.qview ];

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(com.interversehq.qView)$";
      size = "1400 800";
      center = true;
      float = true;
      content = "photo";
    }
  ];
}
