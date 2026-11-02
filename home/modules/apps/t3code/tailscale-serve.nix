{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.t3code.tailscaleServe;
  service = config.custom.t3code.service;

  # HTTPS port on the tailnet name -> local URL behind it
  proxies =
    lib.optionalAttrs (cfg.port != null) {
      ${toString cfg.port} = "http://127.0.0.1:${toString service.port}";
    }
    // cfg.extraProxies;

  tailscale = lib.getExe' cfg.package "tailscale";
  serveAll = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      port: target: "${tailscale} serve --bg --https=${port} ${lib.escapeShellArg target}"
    ) proxies
  );
  unserveAll = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (port: _: "${tailscale} serve --https=${port} off || true") proxies
  );
in
{
  options.custom.t3code.tailscaleServe = {
    enable = lib.mkEnableOption ''
      tailnet-only HTTPS for the T3 Code server (and other local services) with
      `tailscale serve`. A T3 Code client links another machine only over
      https, never plain http. Needs the user as the tailscale operator
      (NixOS: `services.tailscale.extraSetFlags = [ "--operator=<user>" ]`)
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tailscale;
      defaultText = lib.literalExpression "pkgs.tailscale";
      description = "Package providing the `tailscale` CLI.";
    };

    port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = 8443;
      description = ''
        HTTPS port on `https://<host>.<tailnet>.ts.net` for the T3 Code server
        (`custom.t3code.service.port`); `null` serves only `extraProxies`. Not
        the server's own port when it listens on all interfaces, the tailnet
        address included.
      '';
    };

    extraProxies = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "5180" = "http://127.0.0.1:5180";
      };
      description = ''
        More HTTPS ports -> local URLs, e.g. a dev server an agent runs on
        localhost, so it opens from other devices with a real certificate.
      '';
    };
  };

  config = lib.mkIf (config.custom.t3code.enable && cfg.enable) {
    # `tailscale serve --bg` keeps its config in tailscaled's state; this unit
    # sets it at login/boot and takes it down when stopped, so what is served
    # is what the config says.
    systemd.user.services.t3code-tailscale-serve = {
      Unit = {
        Description = "Tailnet HTTPS for T3 Code (tailscale serve)";
        After = lib.optional service.enable "t3code.service";
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "t3code-tailscale-serve" serveAll}";
        ExecStop = "${pkgs.writeShellScript "t3code-tailscale-unserve" unserveAll}";
        # tailscaled may not be logged in yet right after boot
        Restart = "on-failure";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
