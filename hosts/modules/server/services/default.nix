# Docker-backed services for server hosts, each one off by default
# (`custom.services.<name>.enable`). Every container joins one shared bridge
# network, so a cloudflared or reverse proxy container on that network reaches
# the services by container name.
#
# Docker publishes ports through its own iptables rules, past the NixOS
# firewall. `lan.interfaces` closes them on the given interfaces: traffic from
# there to containers is dropped, except for `lan.allowed*Ports` (matched on
# the original destination port, before Docker's DNAT).
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services;
  enabled = lib.any (s: s.enable) [
    cfg.actual
    cfg.cloudflared
    cfg.n8n
    cfg.nextcloud-aio
    cfg.pihole
    cfg.portainer
    cfg.vaultwarden
  ];
in
{
  imports = [
    ./actual.nix
    ./cloudflared.nix
    ./n8n.nix
    ./nextcloud-aio.nix
    ./pihole.nix
    ./portainer.nix
    ./vaultwarden.nix
  ];

  options.custom.services = {
    network = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare_network";
      description = "Docker network shared by the service containers.";
    };

    lan = {
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "enp4s0" ];
        description = "Interfaces from which published container ports are closed (empty: none).";
      };
      allowedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ ];
        description = "Published TCP ports left open on `lan.interfaces`.";
      };
      allowedUDPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ ];
        description = "Published UDP ports left open on `lan.interfaces`.";
      };
    };
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

    # DOCKER-USER is evaluated before Docker's own forwarding rules and is
    # never touched by Docker, so the filter survives Docker restarts.
    networking.firewall = lib.mkIf (cfg.lan.interfaces != [ ]) {
      extraCommands = ''
        ip46tables -N DOCKER-USER 2>/dev/null || true
        ip46tables -N nixos-docker-lan 2>/dev/null || true
        ip46tables -F nixos-docker-lan
        ip46tables -A nixos-docker-lan -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
        ${lib.concatMapStrings (p: ''
          ip46tables -A nixos-docker-lan -p tcp -m conntrack --ctorigdstport ${toString p} -j RETURN
        '') cfg.lan.allowedTCPPorts}
        ${lib.concatMapStrings (p: ''
          ip46tables -A nixos-docker-lan -p udp -m conntrack --ctorigdstport ${toString p} -j RETURN
        '') cfg.lan.allowedUDPPorts}
        ip46tables -A nixos-docker-lan -j DROP
        ${lib.concatMapStrings (i: ''
          ip46tables -D DOCKER-USER -i ${i} -j nixos-docker-lan 2>/dev/null || true
          ip46tables -I DOCKER-USER -i ${i} -j nixos-docker-lan
        '') cfg.lan.interfaces}
      '';
      extraStopCommands = lib.concatMapStrings (i: ''
        ip46tables -D DOCKER-USER -i ${i} -j nixos-docker-lan 2>/dev/null || true
      '') cfg.lan.interfaces;
    };
  };
}
