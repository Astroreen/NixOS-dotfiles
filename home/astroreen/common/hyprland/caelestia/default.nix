{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.caelestia;
in
{
  options = with lib; {
    custom.caelestia = {
      enable = mkEnableOption "Enable Caelestia shell configuration";
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Caelestia shell settings";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    programs.caelestia.systemd.environment = [
      "QT_QPA_PLATFORM=wayland;xcb"
      "XDG_SESSION_TYPE=wayland;xcb"
      "XDG_CURRENT_DESKTOP=Hyprland"
      "XDG_SESSION_DESKTOP=Hyprland"
      "QT_QPA_PLATFORMTHEME=qt6ct"
      "XDG_RUNTIME_DIR=/run/user/1000"
      "WAYLAND_DISPLAY=wayland-1"
      "QUICKSHELL_ENABLE_PORTAL=1"
    ];

    # Home activation is used here to not symlink file into nix store, thus making it writable
    home.activation.caelestiaConfig =
      let
        mergedConfig = cfg.settings // {
          # Additional configuration
          paths = {
            mediaGif = ../../assets/kirby-groove.gif;
            sessionGif = ../../assets/evernight-dance.gif;
          };
        };

        configFile = pkgs.writeText "caelestia-config" (builtins.toJSON mergedConfig);
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONF="$HOME/.config/caelestia/shell.json"
        NEW=${configFile}

        if [ ! -f "$CONF" ] || ! diff -q "$CONF" "$NEW" > /dev/null 2>&1; then
          cp "$NEW" "$CONF"
          chmod 644 "$CONF"
          echo "Caelestia config changed, restarting service..."
          systemctl --user restart caelestia || true
        else
          echo "Caelestia config unchanged, skipping restart."
        fi
      '';
  };
}
