{ pkgs, config, lib, ... }:
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

  wayland.windowManager.hyprland.settings = {
    # NOTE: F12 passthrough submap dropped during hyprlang->Lua migration
    # (wayvnc is disabled; re-add via hl.define_submap if VNC is re-enabled)
    bind = [
      {
        _args = [
          "CTRL + SUPER + SHIFT + semicolon"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wayvncctl output-cycle\")")
        ];
      } # Cycle wayvnc output across monitors
    ];

    window_rule = [
      # VNC viewer should float and be centered
      {
        match.class = "^(realvnc-vncviewer)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(Vncviewer)$";
        float = true;
        center = true;
      }
    ];
  };
}
