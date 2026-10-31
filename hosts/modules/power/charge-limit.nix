{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.power.chargeLimit;
  attr = "/sys/class/power_supply/${cfg.battery}/charge_types";

  # `charge_types` is the kernel's generic knob; on Lenovo IdeaPads `Long_Life`
  # is the firmware's conservation mode (charging stops around 60-80 %).
  battery-charge-limit = pkgs.writeShellScriptBin "battery-charge-limit" ''
    set -eu
    case "''${1:-status}" in
      on) echo ${lib.escapeShellArg cfg.limitedType} > ${attr} ;;
      off) echo ${lib.escapeShellArg cfg.fullType} > ${attr} ;;
      status) ;;
      *) echo "usage: battery-charge-limit [on|off|status]" >&2; exit 2 ;;
    esac
    # The active type is the one in brackets, e.g. "[Standard] Long_Life"
    cat ${attr}
  '';
in
{
  options.custom.power.chargeLimit = {
    enable = lib.mkEnableOption ''
      a battery charge limit at boot (kernel `charge_types`), so a laptop that
      mostly sits on AC is not kept at 100 %. `battery-charge-limit off` charges
      fully until the next boot (or `on`), without sudo
    '';

    battery = lib.mkOption {
      type = lib.types.str;
      default = "BAT0";
      example = "BAT1";
      description = "Battery under /sys/class/power_supply.";
    };

    limitedType = lib.mkOption {
      type = lib.types.str;
      default = "Long_Life";
      description = "`charge_types` value that limits charging (see `cat .../charge_types`).";
    };

    fullType = lib.mkOption {
      type = lib.types.str;
      default = "Standard";
      description = "`charge_types` value that charges to 100 %.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Applied when the battery appears at boot; the `users` group may switch it.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="${cfg.battery}", ATTR{charge_types}="${cfg.limitedType}", RUN+="${pkgs.coreutils}/bin/chgrp users ${attr}", RUN+="${pkgs.coreutils}/bin/chmod g+w ${attr}"
    '';

    environment.systemPackages = [ battery-charge-limit ];
  };
}
