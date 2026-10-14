{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.ai.meridian;
in
{
  options = with lib; {
    custom.ai.meridian = {
      enable = mkEnableOption "Enable Meridian local proxy for Claude Pro/Max integration";
      enableOpencodeIntegration = mkEnableOption "Enable Meridian OpenCode plugin for session tracking and smart model context routing";
      settings = mkOption {
        description = "Meridian settings";
        default = {};
        type = types.submodule {
          options = {
            host = mkOption {
              type = types.str;
              default = "127.0.0.1";
            };

            port = mkOption {
              type = types.int;
              default = 3456;
              description = "Port for the Meridian proxy server";
            };

            meridianInstallDir = mkOption {
              type = types.either types.str types.path;
              default = "${config.home.homeDirectory}/.local/share/meridian";
              description = "Directory in home for Meridian plugin and related files";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Meridian via npm into a local directory (nix-ld handles libsql native binary)
    home.activation.installMeridian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      MERIDIAN_HOME="${cfg.settings.meridianInstallDir}"
      MERIDIAN_BIN="$MERIDIAN_HOME/node_modules/.bin/meridian"
      if [ ! -f "$MERIDIAN_BIN" ]; then
        echo "Installing Meridian proxy..."
        ${pkgs.nodejs}/bin/npm install --prefix "$MERIDIAN_HOME" @rynfar/meridian
      fi
      # meridian-v2 (the opencode v2 plugin) value-imports @opencode-ai/plugin at
      # runtime, but npm only installs @rynfar/meridian's dependencies — the SDK
      # is a devDependency and goes missing, leaving the plugin unloadable.
      # Install the SDK version meridian itself compiled against.
      if [ ! -d "$MERIDIAN_HOME/node_modules/@opencode-ai/plugin" ]; then
        SDK_VER=$(${pkgs.nodejs}/bin/node -p "require('$MERIDIAN_HOME/node_modules/@rynfar/meridian/package.json').devDependencies['@opencode-ai/plugin'] || '0.0.0-beta-18314'")
        echo "Installing @opencode-ai/plugin@$SDK_VER for the meridian v2 plugin..."
        ${pkgs.nodejs}/bin/npm install --prefix "$MERIDIAN_HOME" "@opencode-ai/plugin@$SDK_VER" || echo "warning: @opencode-ai/plugin install failed"
      fi
    '';

    # Meridian as a persistent user service
    systemd.user.services.meridian = {
      Unit = {
        Description = "Meridian - Claude Pro/Max local proxy for opencode";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${cfg.settings.meridianInstallDir}/node_modules/.bin/meridian";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "MERIDIAN_HOST=${cfg.settings.host}"
          "MERIDIAN_PORT=${builtins.toString cfg.settings.port}"
        ];
      };
      Install.WantedBy = [ "default.target" ];
    };

    programs.opencode = lib.mkIf cfg.enableOpencodeIntegration {
      settings = {
        plugin = [
          # Meridian OpenCode plugin - enables session tracking and smart model context routing.
          # opencode v2 loads the meridian-v2 package (plugin directory with its
          # own package.json); the legacy v1 file plugin/meridian.ts is rejected.
          "${cfg.settings.meridianInstallDir}/node_modules/@rynfar/meridian/plugin/meridian-v2/"
        ];

        # Route anthropic models through Meridian (uses Claude Pro/Max via Claude Code SDK)
        provider.anthropic.options = {
          apiKey = "x";
          baseURL = "http://${cfg.settings.host}:${builtins.toString cfg.settings.port}";
        };
      };
    };
  };
}
