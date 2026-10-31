{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.power.battery;
  hyprland = config.wayland.windowManager.hyprland;

  unitsWhen = when: lib.attrNames (lib.filterAttrs (_: unit: unit.when == when) cfg.units);

  batteryMode = pkgs.writeShellScript "battery-mode" ''
    export PATH=${
      lib.makeBinPath (
        [
          pkgs.upower
          pkgs.systemd
        ]
        ++ lib.optional hyprland.enable hyprland.finalPackage
      )
    }:$PATH
    export BM_HYPR_OPTIONS=${lib.escapeShellArg (lib.concatStringsSep " " cfg.hyprland.disableOptions)}
    export BM_BATTERY_UNITS=${lib.escapeShellArg (lib.concatStringsSep " " (unitsWhen "battery"))}
    export BM_LOW_UNITS=${lib.escapeShellArg (lib.concatStringsSep " " (unitsWhen "low"))}
    export BM_RESTORE_UNITS=${
      lib.escapeShellArg (
        lib.concatStringsSep " " (lib.attrNames (lib.filterAttrs (_: u: u.restore) cfg.units))
      )
    }
    export BM_LOW_THRESHOLD=${toString cfg.lowThreshold}
    export BM_BATTERY_MONITORS=${lib.escapeShellArg (builtins.toJSON cfg.hyprland.batteryMonitors)}
    export BM_MONITORS_AT=${cfg.hyprland.monitorsAt}
    export BM_AC_MONITORS=${lib.escapeShellArg (builtins.toJSON cfg.hyprland.acMonitors)}
    exec ${pkgs.python3}/bin/python3 ${./battery-mode.py}
  '';
in
{
  options.custom.power.battery = {
    enable = lib.mkEnableOption ''
      battery mode: while unplugged, turn Hyprland effects off and stop the
      chosen user units, optionally apply other monitor rules (power profiles
      and idle timeouts are the desktop shell's job)
    '';

    lowThreshold = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 20;
      description = "Charge (%) at or below which the `when = \"low\"` units stop.";
    };

    units = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            when = lib.mkOption {
              type = lib.types.enum [
                "battery"
                "low"
              ];
              default = "battery";
              description = "Stop the unit on unplugging, or only once the charge is low.";
            };
            restore = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Start it again on AC if it was running when it was stopped.";
            };
          };
        }
      );
      default = { };
      example = {
        "wayvnc.service".when = "low";
      };
      description = "User units (full names) stopped on battery.";
    };

    hyprland = {
      disableOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = lib.optionals hyprland.enable [
          "animations:enabled"
          "decoration:blur:enabled"
          "decoration:shadow:enabled"
        ];
        defaultText = lib.literalExpression ''[ "animations:enabled" "decoration:blur:enabled" "decoration:shadow:enabled" ]'';
        description = ''
          Boolean Hyprland options (`hyprctl getoption` names) set to false on
          battery and back to their previous values on AC.
        '';
      };

      batteryMonitors = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        default = [ ];
        example = [
          {
            output = "eDP-1";
            mode = "1920x1080@60";
            position = "0x0";
            scale = "1";
          }
        ];
        description = ''
          `hl.monitor` tables applied on battery (e.g. a lower refresh rate),
          replaced by `acMonitors` on AC.
        '';
      };

      monitorsAt = lib.mkOption {
        type = lib.types.enum [
          "battery"
          "low"
        ];
        default = "battery";
        description = "Apply `batteryMonitors` on unplugging, or only once the charge is at or below `lowThreshold`.";
      };

      acMonitors = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        default = hyprland.settings.monitor or [ ];
        defaultText = lib.literalExpression "config.wayland.windowManager.hyprland.settings.monitor";
        description = "`hl.monitor` tables restored on AC after `batteryMonitors`.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.hyprland.batteryMonitors == [ ] || cfg.hyprland.acMonitors != [ ];
        message = "custom.power.battery.hyprland.batteryMonitors needs acMonitors to restore on AC.";
      }
    ];

    systemd.user.services.battery-mode = {
      Unit = {
        Description = "Battery mode (Hyprland effects and services off while unplugged)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = batteryMode;
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
