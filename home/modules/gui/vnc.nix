{ pkgs, config, ... }:
let
  format = pkgs.formats.keyValue { };
in
{
  services.wayvnc = {
    enable = false;
    autoStart = true;
    settings = {
      address = "0.0.0.0";
      port = 5900;
    };
  };

  home.packages = with pkgs; [
    wayvnc  # VNC server for Wayland
    tigervnc # VNC viewer 
  ];

  systemd.user.services."wayvnc" = {
    Unit = {
      Description = "wayvnc VNC server";
      Documentation = [ "man:wayvnc(1)" ];
      After = [
        config.wayland.systemd.target
      ];
      PartOf = [
        config.wayland.systemd.target
      ];
    };
    Service = {
      ExecStart = [ "${pkgs.wayvnc}/bin/wayvnc 0.0.0.0 5900" ];
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = [
      config.wayland.systemd.target
    ];
  };

  xdg.configFile."wayvnc/config".source = format.generate "wayvnc.conf" {
    address = "0.0.0.0";
    port = 5900;
  };

  wayland.windowManager.hyprland = {
    submaps = {
      passthrough.settings.bind = [
        "SUPER, F12, submap, global"
      ];

      global.settings.bind = [
        # Cycle wayvnc output across monitors (wayvncctl is bundled with wayvnc)
        "CTRL SUPER SHIFT, SEMICOLON, exec, wayvncctl output-cycle"
        "SUPER, F12, submap, passthrough"
      ];
    };
    settings.windowrule = [
      # VNC viewer should float and be centered
      "match:class ^(realvnc-vncviewer)$, float on, center on"
      "match:class ^(Vncviewer)$, float on, center on" # VNC viewer should float and be centered
    ];
  };
}
