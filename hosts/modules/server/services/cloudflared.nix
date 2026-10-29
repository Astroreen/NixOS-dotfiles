# Cloudflare Tunnel connector for a remotely managed tunnel: the ingress
# rules live in the Cloudflare dashboard and point at container names on the
# shared network (e.g. http://n8n:5678).
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.cloudflared;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.cloudflared = {
    enable = lib.mkEnableOption "the Cloudflare Tunnel connector in Docker";
    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/cloudflare/cloudflared:latest";
      description = "Container image of cloudflared.";
    };
    environmentFile = lib.mkOption {
      type = lib.types.str;
      example = "/var/lib/secrets/cloudflared.env";
      description = "File with TUNNEL_TOKEN=..., created by hand on the host.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.cloudflared = {
      inherit (cfg) image;
      cmd = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      networks = [ config.custom.services.network ];
      environmentFiles = [ cfg.environmentFile ];
    };

    systemd.services = serviceLib.afterNetwork "docker-cloudflared";
  };
}
