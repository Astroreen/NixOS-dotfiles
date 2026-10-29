# Nextcloud All-in-One behind a reverse proxy (Apache on `apachePort`).
#
# Only the mastercontainer is managed here; it creates and updates the other
# nextcloud-aio-* containers itself and updates its own image through
# watchtower. So it is started with plain `docker run -d --restart always`
# (as the AIO docs do) rather than as an oci-containers systemd unit, which
# would fight watchtower over the container. When the options below change,
# the mastercontainer is recreated; its state lives in the
# nextcloud_aio_mastercontainer volume, so that is safe.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.nextcloud-aio;
  name = "nextcloud-aio-mastercontainer";

  environment = {
    APACHE_PORT = toString cfg.apachePort;
    APACHE_IP_BINDING = cfg.apacheIpBinding;
    APACHE_ADDITIONAL_NETWORK = config.custom.services.network;
    AIO_COMMUNITY_CONTAINERS = lib.concatStringsSep " " cfg.communityContainers;
    NEXTCLOUD_ENABLE_NVIDIA_GPU = lib.boolToString cfg.enableNvidiaGpu;
    NEXTCLOUD_ENABLE_DRI_DEVICE = lib.boolToString cfg.enableDriDevice;
  }
  // lib.optionalAttrs (cfg.nextcloudMount != null) { NEXTCLOUD_MOUNT = cfg.nextcloudMount; }
  // cfg.environment;

  runArgs = lib.escapeShellArgs (
    [
      "--init"
      "--sig-proxy=false"
      "--name"
      name
      "--restart"
      "always"
      "--publish"
      "${toString cfg.interfacePort}:8080"
      "--volume"
      "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
      "--volume"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (k: v: [
        "--env"
        "${k}=${v}"
      ]) environment
    )
    ++ [ cfg.image ]
  );
  hash = builtins.hashString "sha256" runArgs;
in
{
  options.custom.services.nextcloud-aio = {
    enable = lib.mkEnableOption "Nextcloud All-in-One";
    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/nextcloud-releases/all-in-one:latest";
      description = "Mastercontainer image.";
    };
    interfacePort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Host port of the AIO admin interface.";
    };
    apachePort = lib.mkOption {
      type = lib.types.port;
      default = 11000;
      description = "Port of nextcloud-aio-apache, which the reverse proxy talks to.";
    };
    apacheIpBinding = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address apachePort is published on.";
    };
    nextcloudMount = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/mnt/storage";
      description = "Host directory made available to Nextcloud (External storage app).";
    };
    communityContainers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "facerecognition" ];
      description = "AIO community containers to enable.";
    };
    enableNvidiaGpu = lib.mkEnableOption "the NVIDIA GPU in the Nextcloud container";
    enableDriDevice = lib.mkEnableOption "/dev/dri in the Nextcloud container";
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra mastercontainer environment (see the AIO docs).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.${name} = {
      description = "Nextcloud AIO mastercontainer";
      after = [
        "docker.service"
        "docker-network-services.service"
      ];
      requires = [
        "docker.service"
        "docker-network-services.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.virtualisation.docker.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Normally created by the AIO web interface on first start; containers
        # started from a migrated mastercontainer volume fail without it.
        docker network inspect nextcloud-aio >/dev/null 2>&1 \
          || docker network create nextcloud-aio >/dev/null

        current=$(docker inspect --format '{{index .Config.Labels "nixos.config-hash"}}' ${name} 2>/dev/null || true)
        if [ "$current" = "${hash}" ]; then
          docker start ${name} >/dev/null
        else
          docker rm --force ${name} >/dev/null 2>&1 || true
          docker run --detach --label nixos.config-hash=${hash} ${runArgs}
        fi
      '';
    };
  };
}
