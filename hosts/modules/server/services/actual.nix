# Actual Budget sync server.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.actual;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.actual =
    serviceLib.containerOptions {
      name = "actual";
      image = "docker.io/actualbudget/actual-server:latest";
      port = 5006;
      dataDir = "/var/lib/actual";
    }
    // {
      enable = lib.mkEnableOption "Actual Budget server in Docker";
    };

  config = lib.mkIf cfg.enable {
    # Subdirectories are created by Docker, or keep the owner their data came with.
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 root root -" ];

    # Container name kept from the compose stack it replaces, so tunnel
    # ingress rules (actual_server:5006) still match.
    virtualisation.oci-containers.containers.actual_server = {
      inherit (cfg) image;
      ports = [ "${toString cfg.port}:5006" ];
      volumes = [ "${cfg.dataDir}/data:/data" ];
      networks = [ config.custom.services.network ];
      environment = {
        TZ = config.time.timeZone;
      }
      // cfg.environment;
      environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
      extraOptions = [
        "--health-cmd=node src/scripts/health-check.js"
        "--health-interval=60s"
        "--health-start-period=20s"
      ];
    };

    systemd.services = serviceLib.afterNetwork "docker-actual_server";
  };
}
