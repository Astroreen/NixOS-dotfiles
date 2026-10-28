# Nixdatifier — tray app for NixOS generations, generation diffs, flake input
# updates, store usage and dev environments (https://github.com/Muddyblack/nixdatifier).
{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.nixdatifier;
  flakeDir = "${config.home.homeDirectory}/.local/share/nixos";

  # Quick-run commands, run from the flake directory. "rebuild" is what
  # `nixdatifier rebuild` uses.
  commands = [
    {
      label = "rebuild";
      cmd = ''devenv shell -- nixos switch "$(hostname -s)"'';
    }
    {
      label = "home";
      cmd = ''devenv shell -- home switch "$(hostname -s)"'';
    }
    {
      label = "update";
      cmd = "devenv shell -- update-flake";
    }
  ];
in
{
  imports = [ inputs.nixdatifier.homeManagerModules.default ];

  programs.nixdatifier = {
    enable = true;

    # The module autostarts via ~/.config/autostart, but Hyprland runs without
    # UWSM here, so xdg-desktop-autostart.target is never reached. The systemd
    # user service below starts it with the graphical session instead.
    autostart = false;
  };

  systemd.user.services.nixdatifier = {
    Unit = {
      Description = "Nixdatifier tray app";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${cfg.package}/bin/nixdatifier --background";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # The window reads its shared settings only from ~/.config/nixdatifier/config
  # (tui.commands would set an env var that the window ignores), and it writes
  # that file itself. Seed the flake path and commands only when missing, so
  # changes made in the window survive rebuilds.
  home.activation.nixdatifierConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nixdatifier_seed() {
      if ! ${cfg.package}/bin/nixdatifier config get "$1" | grep -q .; then
        run ${cfg.package}/bin/nixdatifier config set "$1" "$2"
      fi
    }
    nixdatifier_seed flake ${lib.escapeShellArg flakeDir}
    nixdatifier_seed commands ${lib.escapeShellArg (builtins.toJSON commands)}
  '';
}
