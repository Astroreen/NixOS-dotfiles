# Generic NixOS module: private Boat.dev API reverse proxy built on the shared
# `custom.services.caddyProxies` module. Injects BOAT_API_KEY only for clients
# presenting `clientTokenFile` over Tailscale Serve HTTPS.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.boatProxy;
in
{
  imports = [
    ./caddy-proxy.nix
  ];

  options.custom.services.boatProxy = {
    enable = lib.mkEnableOption "private Unix-socket reverse proxy that injects BOAT_API_KEY for boat.dev over Tailscale Serve";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8318;
      description = "Tailnet HTTPS port served by `tailscale serve` in front of the Unix socket.";
    };

    upstreamHost = lib.mkOption {
      type = lib.types.str;
      default = "boat.dev";
      description = "Upstream Boat API HTTPS host (dialed on port 443).";
    };

    tailscalePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.tailscale;
      defaultText = lib.literalExpression "pkgs.tailscale";
      description = "Package providing the `tailscale` CLI.";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/boat-api-key";
      description = ''
        Root-owned mode-0600 file containing the real BOAT_API_KEY. Passed to
        the service via systemd LoadCredential so the key never enters the Nix
        store or world-readable paths.
      '';
    };

    clientTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/secrets/boat-proxy-client-token";
      description = ''
        Root-owned mode-0600 file containing the bearer token clients must
        present before the proxy injects BOAT_API_KEY. Prevents unprivileged
        local accounts on the server from abusing Tailscale Serve on the host's
        own Tailscale IP.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    custom.services.caddyProxies.boat-proxy = {
      description = "Boat.dev API key-injecting reverse proxy";
      inherit (cfg) upstreamHost;
      flushInterval = -1;
      credentials = {
        BOAT_API_KEY = cfg.apiKeyFile;
        BOAT_PROXY_CLIENT_TOKEN = cfg.clientTokenFile;
      };
      requiredHeader = {
        name = "Authorization";
        prefix = "Bearer ";
        credential = "BOAT_PROXY_CLIENT_TOKEN";
      };
      setHeaders.Authorization = "Bearer {env.BOAT_API_KEY}";
      tailscaleServe = {
        enable = true;
        inherit (cfg) port;
        package = cfg.tailscalePackage;
      };
    };
  };
}
