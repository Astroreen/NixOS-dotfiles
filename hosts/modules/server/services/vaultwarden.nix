# Vaultwarden: Bitwarden-compatible password manager.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.vaultwarden;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.vaultwarden =
    serviceLib.containerOptions {
      name = "vaultwarden";
      image = "ghcr.io/dani-garcia/vaultwarden:alpine";
      port = 8812;
      dataDir = "/var/lib/vaultwarden";
    }
    // {
      enable = lib.mkEnableOption "Vaultwarden in Docker";
      domain = lib.mkOption {
        type = lib.types.str;
        example = "https://bw.example.com";
        description = "Public URL, used in links and for WebAuthn.";
      };
    };

  config = lib.mkIf cfg.enable {
    # Subdirectories are created by Docker, or keep the owner their data came with.
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 root root -" ];

    virtualisation.oci-containers.containers.vaultwarden = {
      inherit (cfg) image;
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      volumes = [ "${cfg.dataDir}/data:/data" ];
      networks = [ config.custom.services.network ];
      environment = {
        DOMAIN = cfg.domain;
        ROCKET_PORT = toString cfg.port;
        SIGNUPS_ALLOWED = lib.mkDefault "false";
        TZ = config.time.timeZone;
      }
      // cfg.environment;
      environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    };

    systemd.services = serviceLib.afterNetwork "docker-vaultwarden";
  };
}
