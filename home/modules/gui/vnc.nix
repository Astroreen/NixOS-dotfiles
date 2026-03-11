{ pkgs, ... }:
{
  services.wayvnc = {
    enable = true;
    autoStart = true;
    settings = {
      address = "0.0.0.0";
      port = 5900;
    };
  };

  home.packages = with pkgs; [
    realvnc-vnc-viewer
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    submap = global
    bind = SUPER, F10, submap, passthrough
    submap = passthrough
    bind = SUPER, F10, submap, global
    submap = global
  '';
}
