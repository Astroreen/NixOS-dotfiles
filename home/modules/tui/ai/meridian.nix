{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.meridian;
in
{
  options = with lib; {
    custom.meridian = {
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
      MERIDIAN_BIN="${cfg.settings.meridianInstallDir}/node_modules/.bin/meridian"
      if [ ! -f "$MERIDIAN_BIN" ]; then
        echo "Installing Meridian proxy..."
        ${pkgs.nodejs}/bin/npm install --prefix "${cfg.settings.meridianInstallDir}" @rynfar/meridian
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
          # Meridian OpenCode plugin - enables session tracking and smart model context routing
          "${cfg.settings.meridianInstallDir}/node_modules/@rynfar/meridian/plugin/meridian.ts"
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
