# Pi-hole: network-wide DNS ad blocker. Publishes DNS (53) and its web UI.
{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.services.pihole;
  serviceLib = import ./lib.nix { inherit lib; };
in
{
  options.custom.services.pihole =
    serviceLib.containerOptions {
      name = "pihole";
      image = "docker.io/pihole/pihole:latest";
      port = 8573;
      dataDir = "/var/lib/pihole";
    }
    // {
      enable = lib.mkEnableOption "Pi-hole in Docker";
      forwardZones = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          "example.ts.net" = "100.100.100.100";
        };
        description = "DNS zones answered by another server instead of the upstreams (zone -> server).";
      };
    };

  config = lib.mkIf cfg.enable {
    # Subdirectories are created by Docker, or keep the owner their data came with.
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 root root -" ];

    virtualisation.oci-containers.containers.pihole = {
      inherit (cfg) image;
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "${toString cfg.port}:${toString cfg.port}/tcp"
      ];
      volumes = [
        "${cfg.dataDir}/etc-pihole:/etc/pihole"
        "${cfg.dataDir}/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
      networks = [ config.custom.services.network ];
      environment = {
        TZ = config.time.timeZone;
        FTLCONF_webserver_port = toString cfg.port;
        # Answer queries from the LAN, not only from the local subnet.
        FTLCONF_dns_listeningMode = "all";
      }
      // lib.optionalAttrs (cfg.forwardZones != { }) {
        FTLCONF_misc_dnsmasq_lines = lib.concatStringsSep ";" (
          lib.mapAttrsToList (zone: server: "server=/${zone}/${server}") cfg.forwardZones
        );
      }
      // cfg.environment;
      # FTLCONF_webserver_api_password=... for the web UI.
      environmentFiles = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    };

    systemd.services = serviceLib.afterNetwork "docker-pihole";

    # The published port 53 needs the host's own DNS stub out of the way.
    services.resolved.settings.Resolve.DNSStubListener = "no";

    # DNS is the one service the LAN talks to directly.
    custom.services.lan = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
