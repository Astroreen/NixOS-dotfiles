{ pkgs, ... }:
{
  # LocalSend as an always-on "server": the GUI is the only variant packaged
  # in nixpkgs (the official `localsend-cli` added in v1.18 is not packaged),
  # so run it hidden in the tray from the graphical session. It listens on the
  # LocalSend port 53317 (TCP+UDP), already opened in
  # hosts/astroreen/common/network.nix.
  #
  # `--hidden` is the app's own start-hidden flag (see
  # app/lib/util/native/autostart_helper.dart upstream). `Restart = "always"`
  # keeps the receiver up even if the window is closed; stop it with
  # `systemctl --user stop localsend`.
  home.packages = [ pkgs.localsend ];

  systemd.user.services.localsend = {
    Unit = {
      Description = "LocalSend file transfer server (always-on)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.localsend}/bin/localsend_app --hidden";
      Restart = "always";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
