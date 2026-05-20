{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher
  ];

  wayland.windowManager.hyprland.settings.windowrule = [
    "match:class minecraft, center on, float on"
  ];
}
