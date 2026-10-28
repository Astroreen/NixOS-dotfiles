{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.custom.dux;
in
{
  imports = [
    inputs.dux-shell.homeModules.default # Dux shell module (programs.dank-material-shell)
  ];

  options = with lib; {
    custom.dux = {
      enable = mkEnableOption "Dux shell (formerly DankMaterialShell)";
      quickshellPackage = mkOption {
        type = types.package;
        default = pkgs.quickshell;
        defaultText = literalExpression "pkgs.quickshell";
        description = "Quickshell package the shell runs on.";
      };
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Dux shell settings, copied (writable) to ~/.config/dms/settings.json.
          Empty keeps whatever the dux settings UI saved there.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      quickshell.package = cfg.quickshellPackage;
      systemd.enable = true;
      # Keep empty so the upstream module does not symlink read-only
      # settings.json; `settings` writes a mutable copy instead.
      settings = { };
    };

    # Same fd exhaustion as caelestia.service (see the caelestia module):
    # the upstream unit does not raise the 1024 soft limit.
    systemd.user.services.dms.Service.LimitNOFILE = lib.mkDefault "524288";

    # Home activation is used here to not symlink file into nix store, thus making it writable
    home.activation.duxConfig = lib.mkIf (cfg.settings != { }) (
      let
        configFile = pkgs.writeText "dux-config" (builtins.toJSON cfg.settings);
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONF="${config.home.homeDirectory}/.config/dms/settings.json"
        NEW=${configFile}

        if [ ! -f "$CONF" ] || ! diff -q "$CONF" "$NEW" > /dev/null 2>&1; then
          mkdir -p "$(dirname "$CONF")"
          cp "$NEW" "$CONF"
          chmod 644 "$CONF"
          systemctl --user restart dms || true
        fi
      ''
    );
  };
}
