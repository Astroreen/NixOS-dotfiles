# n8n: workflow automation. Runs as uid/gid 1000 (`node`) inside the image.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.n8n;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.n8n =
    serviceLib.containerOptions {
      name = "n8n";
      image = "docker.io/n8nio/n8n:latest";
      port = 5678;
      dataDir = "/var/lib/n8n";
    }
    // {
      enable = lib.mkEnableOption "n8n in Docker";
      host = lib.mkOption {
        type = lib.types.str;
        example = "n8n.example.com";
        description = "Public host name; webhooks are served from https://<host>/.";
      };
    };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 root root -"
      "d ${cfg.dataDir}/data 0700 1000 1000 -"
    ];

    virtualisation.oci-containers.containers.n8n = {
      inherit (cfg) image;
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      volumes = [ "${cfg.dataDir}/data:/home/node/.n8n" ];
      networks = [ config.custom.services.network ];
      environment = {
        N8N_HOST = cfg.host;
        N8N_PORT = toString cfg.port;
        N8N_PROTOCOL = "https";
        WEBHOOK_URL = "https://${cfg.host}/";
        GENERIC_TIMEZONE = config.time.timeZone;
        TZ = config.time.timeZone;
      }
      // cfg.environment;
      environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    };

    systemd.services = serviceLib.afterNetwork "docker-n8n";
  };
}
