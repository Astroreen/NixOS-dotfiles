{ pkgs, ... }:
{
  # Postman: API development environment
  home.packages = [ pkgs.postman ];

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(Postman)$";
      size = "1400 800";
      center = true;
      float = true;
    }
  ];
}
