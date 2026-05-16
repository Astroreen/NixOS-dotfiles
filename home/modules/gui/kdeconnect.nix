{ pkgs, ... }:
{
  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };

  wayland.windowManager.hyprland.settings.windowrule = [
    # KDE Connect daemon window
    "match:class ^(org.kde.kdeconnect.daemon)$, fullscreen_state 0 3, size 100% 100%, center on, no_blur on, no_anim on, no_dim on, no_focus on, no_shadow on, rounding 0, no_follow_mouse on, border_size 0, rounding 0"
    
  ];
}
