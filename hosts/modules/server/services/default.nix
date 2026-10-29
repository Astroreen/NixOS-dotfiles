# Docker-backed services for server hosts, each one off by default
# (`custom.services.<name>.enable`). Every container joins one shared bridge
# network, so a cloudflared or reverse proxy container on that network reaches
# the services by container name.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services;
  enabled = lib.any (s: s.enable) [
    cfg.actual
    cfg.n8n
    cfg.nextcloud-aio
    cfg.pihole
    cfg.vaultwarden
  ];
in
{
  imports = [
    ./actual.nix
    ./n8n.nix
    ./nextcloud-aio.nix
    ./pihole.nix
    ./vaultwarden.nix
  ];

  options.custom.services.network = lib.mkOption {
    type = lib.types.str;
    default = "cloudflare_network";
    description = "Docker network shared by the service containers.";
  };

  config = lib.mkIf enabled {
    virtualisation.oci-containers.backend = "docker";

    # Containers attached to it are ordered after this unit (see each module).
    systemd.services.docker-network-services = {
      description = "Docker network ${cfg.network}";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.virtualisation.docker.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker network inspect ${cfg.network} >/dev/null 2>&1 \
          || docker network create ${cfg.network}
      '';
    };
  };
}
