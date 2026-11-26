# Generic Home Manager module for boat.dev CLI and the t3boat MCP bridge.
# Routes Boat API calls through a private key-injecting reverse proxy
# (`proxyUrl`, e.g. `custom.services.boatProxy` over Tailscale Serve),
# authenticating to the proxy with `proxyTokenFile` (mode 0600) so the real
# BOAT_API_KEY never leaves the proxy host.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai.boat;

  proxyOrigin = lib.removeSuffix "/" cfg.proxyUrl;

  hasT3Code =
    (config.custom.t3code.enable or false) && (config.custom.t3code.package or null) != null;
  t3Package = if hasT3Code then config.custom.t3code.package else null;
  t3Home =
    if hasT3Code && (config.custom.t3code.stateDir or null) != null then
      builtins.dirOf config.custom.t3code.stateDir
    else
      null;

  t3boatPath = lib.makeBinPath (
    [
      pkgs.coreutils
      pkgs.git
      pkgs.nodejs_24
    ]
    ++ lib.optional hasT3Code t3Package
  );

  loadProxyToken = ''
    if [ -z "''${BOAT_API_KEY:-}" ]; then
      tokenFile=${lib.escapeShellArg cfg.proxyTokenFile}
      if [ -r "$tokenFile" ]; then
        BOAT_API_KEY=$(tr -d '\r\n' < "$tokenFile")
        export BOAT_API_KEY
      fi
    fi
    if [ -z "''${BOAT_API_KEY:-}" ]; then
      echo "[boat] BOAT_API_KEY is not set and ${cfg.proxyTokenFile} is missing or empty." >&2
      exit 1
    fi
  '';

  boatWrapped = pkgs.writeShellScriptBin "boat" ''
    set -euo pipefail
    export BOAT_NO_UPDATE=1

    # Interactive account-management commands talk to boat.dev directly;
    # sandbox API calls go through the tailnet proxy unless BOAT_DIRECT=1.
    case "''${1:-}" in
      onboard|login|logout|api-key|dashboard|help|-h|--help|-V|--version) ;;
      *)
        if [ "''${BOAT_DIRECT:-0}" != "1" ]; then
          : "''${BOAT_API_URL:=${proxyOrigin}}"
          export BOAT_API_URL
          ${loadProxyToken}
        fi
        ;;
    esac

    exec ${lib.getExe cfg.package} "$@"
  '';

  t3boatMcp = pkgs.writeShellScriptBin "t3boat-mcp" ''
    set -euo pipefail
    export PATH=${lib.escapeShellArg t3boatPath}:"$PATH"

    : "''${BOAT_API_BASE:=${proxyOrigin}/api/v1}"
    export BOAT_API_BASE
    ${loadProxyToken}

    ${lib.optionalString hasT3Code ''
      : "''${T3BOAT_T3_CLI:=${t3Package}/bin/t3}"
      # t3boat strips prerelease suffixes from `t3 --version`, which breaks on
      # T3 Code nightlies before the matching stable tag exists. Pin the exact
      # installed version so `t3.codes/install.sh` installs the matching build.
      : "''${T3BOAT_T3_VERSION:=${t3Package.version}}"
      export T3BOAT_T3_CLI T3BOAT_T3_VERSION
    ''}
    ${lib.optionalString (t3Home != null) ''
      : "''${T3BOAT_T3_HOME:=${t3Home}}"
      export T3BOAT_T3_HOME
    ''}
    ${lib.optionalString (cfg.defaultSnapshot != null) ''
      : "''${T3BOAT_DEFAULT_SNAPSHOT:=${cfg.defaultSnapshot}}"
      export T3BOAT_DEFAULT_SNAPSHOT
    ''}
    ${lib.optionalString (cfg.forwardEnv != [ ]) ''
      : "''${T3BOAT_FORWARD_ENV:=${lib.concatStringsSep "," cfg.forwardEnv}}"
      export T3BOAT_FORWARD_ENV
    ''}

    exec ${lib.getExe cfg.t3boatPackage} "$@"
  '';

  snapshotBuilderPath = lib.makeBinPath [
    boatWrapped
    pkgs.coreutils
    pkgs.gnutar
    pkgs.gzip
    pkgs.jq
  ];

  boatRebuildSnapshot = pkgs.writeShellScriptBin "boat-rebuild-snapshot" ''
    set -euo pipefail
    export PATH=${lib.escapeShellArg snapshotBuilderPath}:"$PATH"
    export BOAT_DEFAULT_SNAPSHOT=${lib.escapeShellArg (cfg.defaultSnapshot or "dev-base")}
    export AGY_VERSION=${lib.escapeShellArg cfg.snapshot.agyVersion}
    export AGY_URL=${lib.escapeShellArg "https://storage.googleapis.com/antigravity-public/antigravity-cli/${cfg.snapshot.agyWholeVersion}/linux-x64/cli_linux_x64.tar.gz"}
    export AGY_SHA256_SRI=${lib.escapeShellArg cfg.snapshot.agySha256}
    export OPENCODE_VERSION=${lib.escapeShellArg cfg.snapshot.opencodeVersion}
    export OPENCODE_URL=${lib.escapeShellArg "https://github.com/anomalyco/opencode/releases/download/v${cfg.snapshot.opencodeVersion}/opencode-linux-x64.tar.gz"}
    export OPENCODE_SHA256_HEX=${lib.escapeShellArg cfg.snapshot.opencodeSha256}
    export CBM_VERSION=${lib.escapeShellArg cfg.snapshot.cbmVersion}
    export GRAPHIFY_VERSION=${lib.escapeShellArg cfg.snapshot.graphifyVersion}
    ${lib.optionalString hasT3Code ''
      export T3_VERSION=${lib.escapeShellArg t3Package.version}
    ''}
    exec ${pkgs.bash}/bin/bash ${./boat-rebuild-snapshot.sh} "$@"
  '';

  boatShellFunction = ''
    boat() {
      local current_file convo_file old_current_file old_convo_file boat_status current_id current_convo
      current_file=$(mktemp)
      convo_file=$(mktemp)
      old_current_file=''${BOAT_CURRENT_ID_FILE-}
      old_convo_file=''${BOAT_CURRENT_CONVO_FILE-}
      export BOAT_CURRENT_ID_FILE="$current_file"
      export BOAT_CURRENT_CONVO_FILE="$convo_file"
      command ${lib.getExe boatWrapped} "$@"
      boat_status=$?
      if [ "$boat_status" -eq 0 ]; then
        case "''${1:-}" in
          new|start|fork)
            if [ -s "$current_file" ]; then
              current_id=$(tr -d '[:space:]' < "$current_file")
              if [ -n "$current_id" ]; then export BOAT_CURRENT_ID="$current_id"; fi
            fi
            ;;
          prompt)
            if [ -s "$convo_file" ]; then
              IFS= read -r current_convo < "$convo_file" || current_convo=""
              if [ -n "$current_convo" ]; then export BOAT_CURRENT_CONVO="$current_convo"; fi
            fi
            ;;
        esac
      fi
      if [ -n "$old_current_file" ]; then export BOAT_CURRENT_ID_FILE="$old_current_file"; else unset BOAT_CURRENT_ID_FILE; fi
      if [ -n "$old_convo_file" ]; then export BOAT_CURRENT_CONVO_FILE="$old_convo_file"; else unset BOAT_CURRENT_CONVO_FILE; fi
      rm -f "$current_file" "$convo_file"
      return "$boat_status"
    }
  '';
in
{
  options.custom.ai.boat = {
    enable = lib.mkEnableOption "boat.dev CLI and the t3boat MCP bridge for T3 Code";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../package/terminal/ai/boat.nix { };
      description = "Boat CLI package to install.";
    };

    t3boatPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../package/terminal/ai/t3boat.nix { };
      description = "t3code-boat package backing the t3boat-mcp wrapper.";
    };

    proxyUrl = lib.mkOption {
      type = lib.types.str;
      example = "https://server.tailnet.ts.net:8318";
      description = ''
        Origin URL of the private Boat API reverse proxy (e.g.
        `custom.services.boatProxy` exposed via Tailscale Serve). Both
        `t3boat-mcp` and `boat` route API requests through this origin so no
        real Boat API key is stored on client hosts.
      '';
    };

    proxyTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/boat/proxy-token";
      description = ''
        Path to a mode-0600 file holding the client bearer token accepted by
        `proxyUrl` (never the upstream BOAT_API_KEY itself).
      '';
    };

    forwardEnv = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Local environment variable names forwarded to sandboxes via T3BOAT_FORWARD_ENV.";
    };

    defaultSnapshot = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "dev-base";
      description = ''
        Default Boat saved snapshot passed to `t3boat` via `T3BOAT_DEFAULT_SNAPSHOT`
        and targeted by `boat-rebuild-snapshot`. Pass `from: "none"` to bypass.
      '';
    };

    snapshot = {
      agyVersion = lib.mkOption {
        type = lib.types.str;
        default = "1.5.13";
        description = "Pinned Antigravity CLI (`agy`) version installed in the Boat snapshot.";
      };

      agyWholeVersion = lib.mkOption {
        type = lib.types.str;
        default = "1.5.13-5999302598852608";
        description = "Full GCS build version string for the pinned Antigravity CLI release.";
      };

      agySha256 = lib.mkOption {
        type = lib.types.str;
        default = "sha256-f6nMbfDQlWJpPWN8QGqGwbD1KrM2RxSx/S15zGBg1LI=";
        description = "SRI SHA-256 hash of `cli_linux_x64.tar.gz` for `agyWholeVersion`.";
      };

      opencodeVersion = lib.mkOption {
        type = lib.types.str;
        default = "2.4.2";
        description = "Pinned OpenCode v2 version installed in the Boat snapshot.";
      };

      opencodeSha256 = lib.mkOption {
        type = lib.types.str;
        default = "452912288f934d1771bd5bd0d8611ba3a6adc3db3ac3333c37facf373770ba66";
        description = "Hex SHA-256 hash of `opencode-linux-x64.tar.gz` for `opencodeVersion`.";
      };

      cbmVersion = lib.mkOption {
        type = lib.types.str;
        default = "v0.12.1";
        description = "Pinned codebase-memory-mcp version installed in the Boat snapshot.";
      };

      graphifyVersion = lib.mkOption {
        type = lib.types.str;
        default = "0.9.119";
        description = "Pinned graphifyy PyPI version installed in the Boat snapshot.";
      };
    };

    enableShellIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wrap `boat` in interactive bash/zsh sessions so `current` tracks the latest sandbox.";
    };

    enableMcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the `t3boat` and `boat-docs` MCP servers in programs.mcp.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      boatWrapped
      t3boatMcp
      boatRebuildSnapshot
    ];

    xdg.configFile."ascii/boat/config.json".text = builtins.toJSON {
      api_url = "https://boat.dev";
      channel = "prod";
    };

    programs = {
      mcp.servers = lib.mkIf cfg.enableMcp {
        t3boat = {
          disabled = false;
          command = lib.mkForce "${t3boatMcp}/bin/t3boat-mcp";
        };
        boat-docs.disabled = false;
      };

      bash.initExtra = lib.mkIf cfg.enableShellIntegration boatShellFunction;
      zsh.initContent = lib.mkIf cfg.enableShellIntegration (lib.mkAfter boatShellFunction);
    };
  };
}
