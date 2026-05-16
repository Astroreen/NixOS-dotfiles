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

  wayland.windowManager.hyprland.settings.windowrule = [
    # VNC viewer should float and be centered
    "match:class ^(realvnc-vncviewer)$, float on, center on"
    "match:class ^(Vncviewer)$, float on, center on" # VNC viewer should float and be centered
  ];
}
