{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.localsend;
in
{
  options.custom.localsend = {
    enable = lib.mkEnableOption "LocalSend file transfer, with a `localsend` user service that runs it hidden in the tray";

    package = lib.mkPackageOption pkgs "localsend" { };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start the receiver with the graphical session (an always-on "server").
        Otherwise it runs while opened from the launcher, or after
        `systemctl --user start localsend`.
      '';
    };
  };

  # The GUI is the only variant packaged in nixpkgs (the official
  # `localsend-cli` added in v1.18 is not packaged), hence a hidden GUI as the
  # receiver. It listens on port 53317 (TCP+UDP); opening it is the host's job.
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # `--hidden` is the app's own start-hidden flag (see
    # app/lib/util/native/autostart_helper.dart upstream). `Restart = "always"`
    # keeps the receiver up even if the window is closed; stop it with
    # `systemctl --user stop localsend`.
    systemd.user.services.localsend = {
      Unit = {
        Description = "LocalSend file transfer server";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe' cfg.package "localsend_app"} --hidden";
        Restart = "always";
        RestartSec = "3s";
      };
      Install.WantedBy = lib.mkIf cfg.autostart [ "graphical-session.target" ];
    };
  };
}
