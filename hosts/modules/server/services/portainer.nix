# Portainer CE: web UI for the host's Docker (HTTPS, self-signed certificate).
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.portainer;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.portainer =
    serviceLib.containerOptions {
      name = "portainer";
      image = "docker.io/portainer/portainer-ce:lts";
      port = 9443;
      dataDir = "/var/lib/portainer";
    }
    // {
      enable = lib.mkEnableOption "Portainer in Docker";
    };

  config = lib.mkIf cfg.enable {
    # Subdirectories are created by Docker, or keep the owner their data came with.
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 root root -" ];

    virtualisation.oci-containers.containers.portainer = {
      inherit (cfg) image;
      ports = [ "${toString cfg.port}:9443" ];
      volumes = [
        "${cfg.dataDir}/data:/data"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      networks = [ config.custom.services.network ];
      inherit (cfg) environment;
      environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    };

    systemd.services = serviceLib.afterNetwork "docker-portainer";
  };
}
