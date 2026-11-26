# Generic NixOS module for isolated, Caddy-backed reverse proxies listening on
# private Unix sockets (/run/<name>/<name>.sock, mode 0600 in a 0700 dir).
# Each instance gets its own DynamicUser systemd unit, LoadCredential secrets
# (exported into Caddy's environment, never in /nix/store or argv), optional
# header auth gate (401 on mismatch), and optional root Tailscale Serve unit.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.services.caddyProxies;
  enabledProxies = lib.filterAttrs (_: p: p.enable) cfg;

  proxyModule =
    { name, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable this Caddy reverse proxy instance.";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = "Caddy reverse proxy (${name})";
          description = "systemd unit description for this proxy.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.caddy;
          defaultText = lib.literalExpression "pkgs.caddy";
          description = "Caddy package to run.";
        };

        upstreamHost = lib.mkOption {
          type = lib.types.str;
          description = "Upstream host to dial.";
        };

        upstreamPort = lib.mkOption {
          type = lib.types.port;
          default = 443;
          description = "Upstream port to dial.";
        };

        upstreamTls = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Connect to the upstream over TLS.";
        };

        flushInterval = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          example = -1;
          description = "Caddy reverse_proxy `flush_interval` (-1 streams immediately).";
        };

        credentials = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            UPSTREAM_API_KEY = "/var/lib/secrets/service-api-key";
          };
          description = ''
            Map of environment variable name -> root-owned secret file path.
            Loaded via systemd LoadCredential and exported to Caddy (referenced
            as `{env.<VAR>}` in headers) so secrets never enter /nix/store or
            process argv.
          '';
        };

        requiredHeader = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "HTTP request header name required for access.";
                };
                prefix = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Optional literal prefix prepended before the credential value (e.g. `Bearer `).";
                };
                credential = lib.mkOption {
                  type = lib.types.str;
                  description = "Key in `credentials` whose value is compared literally via Caddy CEL `==` (no wildcard expansion).";
                };
              };
            }
          );
          default = null;
          description = "Optional literal header auth gate; non-matching requests receive HTTP 401.";
        };

        setHeaders = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Request headers set on proxied upstream requests (supports `{env.VAR}`).";
        };

        tailscaleServe = {
          enable = lib.mkEnableOption "expose this proxy's Unix socket over Tailscale Serve HTTPS";

          port = lib.mkOption {
            type = lib.types.port;
            description = "Tailnet HTTPS port served by `tailscale serve`.";
          };

          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.tailscale;
            defaultText = lib.literalExpression "pkgs.tailscale";
            description = "Package providing the `tailscale` CLI.";
          };
        };
      };
    };

  mkProxyServices =
    name: p:
    let
      socketPath = "/run/${name}/${name}.sock";
      credentialPaths = lib.attrValues p.credentials;

      reverseProxyHandler = {
        handler = "reverse_proxy";
        transport = {
          protocol = "http";
        }
        // lib.optionalAttrs p.upstreamTls {
          tls = { };
        };
        upstreams = [
          { dial = "${p.upstreamHost}:${toString p.upstreamPort}"; }
        ];
      }
      // lib.optionalAttrs (p.flushInterval != null) {
        flush_interval = p.flushInterval;
      }
      // lib.optionalAttrs (p.setHeaders != { }) {
        headers.request.set = lib.mapAttrs (_: v: [ v ]) p.setHeaders;
      };

      authExpr =
        let
          rh = p.requiredHeader;
          rhs =
            if rh.prefix == "" then
              "{env.${rh.credential}}"
            else
              "${builtins.toJSON rh.prefix} + {env.${rh.credential}}";
        in
        "{http.request.header.${rh.name}} == ${rhs}";

      routes =
        if p.requiredHeader != null then
          [
            {
              group = name;
              match = [
                {
                  expression = authExpr;
                }
              ];
              handle = [ reverseProxyHandler ];
            }
            {
              group = name;
              handle = [
                {
                  handler = "static_response";
                  status_code = 401;
                  body = "unauthorized";
                }
              ];
            }
          ]
        else
          [
            {
              handle = [ reverseProxyHandler ];
            }
          ];

      caddyConfig = pkgs.writeText "${name}-caddy.json" (
        builtins.toJSON {
          admin.disabled = true;
          apps.http.servers.srv0 = {
            listen = [ "unix/${socketPath}|0600" ];
            automatic_https.disable = true;
            inherit routes;
          };
        }
      );

      loadCredLines = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (envVar: path: ''
          val=$(tr -d '\r\n' < "$CREDENTIALS_DIRECTORY/${envVar}")
          if [ -z "$val" ]; then
            echo "${name}: ${path} is empty; refusing to start" >&2
            exit 1
          fi
          export ${envVar}="$val"
        '') p.credentials
      );

      startScript = pkgs.writeShellScript "${name}-start" ''
        set -euo pipefail
        ${loadCredLines}
        exec ${lib.getExe p.package} run --config ${caddyConfig}
      '';

      tailscale = lib.getExe' p.tailscaleServe.package "tailscale";
      serveStart = pkgs.writeShellScript "${name}-tailscale-serve" ''
        set -euo pipefail
        for _ in $(seq 1 50); do
          [ -S ${lib.escapeShellArg socketPath} ] && break
          sleep 0.2
        done
        [ -S ${lib.escapeShellArg socketPath} ] || {
          echo "${name}-tailscale-serve: ${socketPath} not ready" >&2
          exit 1
        }
        exec ${tailscale} serve --bg --https=${toString p.tailscaleServe.port} unix:${socketPath}
      '';
      serveStop = pkgs.writeShellScript "${name}-tailscale-unserve" ''
        ${tailscale} serve --https=${toString p.tailscaleServe.port} off || true
      '';
    in
    {
      ${name} = {
        inherit (p) description;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig = lib.optionalAttrs (credentialPaths != [ ]) {
          ConditionPathExists = credentialPaths;
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = startScript;
          Restart = "on-failure";
          RestartSec = 5;

          DynamicUser = true;
          RuntimeDirectory = name;
          RuntimeDirectoryMode = "0700";
          StateDirectory = name;
          Environment = [
            "XDG_DATA_HOME=/var/lib/${name}"
            "XDG_CONFIG_HOME=/var/lib/${name}"
          ];

          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          LockPersonality = true;
          CapabilityBoundingSet = "";
        }
        // lib.optionalAttrs (p.credentials != { }) {
          LoadCredential = lib.mapAttrsToList (envVar: path: "${envVar}:${path}") p.credentials;
        };
      };
    }
    // lib.optionalAttrs p.tailscaleServe.enable {
      "${name}-tailscale-serve" = {
        description = "Tailnet HTTPS endpoint for ${name} (tailscale serve)";
        bindsTo = [ "${name}.service" ];
        after = [
          "${name}.service"
          "tailscaled.service"
        ];
        wantedBy = [ "${name}.service" ];
        unitConfig = lib.optionalAttrs (credentialPaths != [ ]) {
          ConditionPathExists = credentialPaths;
        };

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = serveStart;
          ExecStop = serveStop;
          # tailscaled may still be coming online right after boot.
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };
in
{
  options.custom.services.caddyProxies = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule proxyModule);
    default = { };
    description = "Isolated Caddy Unix-socket reverse proxies with optional LoadCredential auth and Tailscale Serve.";
  };

  config = lib.mkIf (enabledProxies != { }) {
    systemd.services = lib.mkMerge (lib.mapAttrsToList mkProxyServices enabledProxies);
  };
}
