{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher
  ];

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "minecraft";
      center = true;
      float = true;
    }
  ];
}
