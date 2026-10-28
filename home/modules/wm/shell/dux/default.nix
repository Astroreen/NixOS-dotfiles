{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.custom.dux;
  shellLib = import ../lib.nix { inherit pkgs lib; };
  hyprlandDir = "${config.xdg.configHome}/hypr";
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
          Default dux shell settings, merged into the writable
          ~/.config/dms/settings.json: only keys the file does not have yet are
          added, so changes made in the dux settings UI survive a rebuild (unless `overrideSettings`).
        '';
      };
      overrideSettings = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether `settings` win over values already in ~/.config/dms/settings.json
          (e.g. saved from the shell's settings UI). Off: `settings` only
          fill keys the file does not have yet. Keys only the file has are
          kept either way.
        '';
      };
      settingsOverrides = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Recursively merged over settings.json and `settings`, always winning.";
      };
      hyprlandIncludes = mkOption {
        type = types.listOf types.str;
        default = [
          "colors"
          "outputs"
          "layout"
          "cursor"
          "input"
          "windowrules"
          "binds-user"
        ];
        description = ''
          Fragments of ~/.config/hypr/dms/ that dux writes from its settings UI
          (displays, keybind overrides, layout, ...), each `require`d at the end
          of hyprland.lua. Dux would append these lines itself, which fails on
          the read-only home-manager hyprland.lua. Empty disables it.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      # Player names come from desktop entries (see the patch), so an app
      # reporting its app id as MPRIS identity still shows a readable name.
      package = inputs.dux-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          patch -d $out/share/quickshell/dms -p1 < ${./mpris-display-name.patch}
        '';
      });
      quickshell.package = cfg.quickshellPackage;
      systemd.enable = true;
      # Keep empty so the upstream module does not symlink read-only
      # settings.json; `settings` merges into a mutable copy instead.
      settings = { };
    };

    # Same fd exhaustion as caelestia.service (see the caelestia module):
    # the upstream unit does not raise the 1024 soft limit.
    systemd.user.services.dms.Service.LimitNOFILE = lib.mkDefault "524288";

    # extraConfig renders last, so the dux fragments override the declarative
    # settings (monitors, binds) above them, as dux expects.
    wayland.windowManager.hyprland.extraConfig =
      lib.mkIf (config.wayland.windowManager.hyprland.enable && cfg.hyprlandIncludes != [ ])
        ''
          -- Dux shell managed settings (~/.config/hypr/dms)
          ${lib.concatMapStrings (name: "require(\"dms.${name}\")\n") cfg.hyprlandIncludes}'';

    home.activation = {
      # Home activation is used here to not symlink file into nix store, thus making it writable
      duxConfig = lib.mkIf (cfg.settings != { } || cfg.settingsOverrides != { }) (
        shellLib.mkJsonConfigActivation {
          path = "${config.xdg.configHome}/dms/settings.json";
          defaults = cfg.settings;
        overrideDefaults = cfg.overrideSettings;
          overrides = cfg.settingsOverrides;
          service = "dms";
        }
      );

      # `require` errors on a missing module, so create the fragments dux has
      # not written yet, before the new hyprland.lua is linked (and reloaded).
      # `touch` keeps whatever dux already wrote.
      duxHyprlandFragments = lib.mkIf (cfg.hyprlandIncludes != [ ]) (
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          mkdir -p ${lib.escapeShellArg "${hyprlandDir}/dms"}
          ${lib.concatMapStrings (
            name: "touch ${lib.escapeShellArg "${hyprlandDir}/dms/${name}.lua"}\n"
          ) cfg.hyprlandIncludes}
        ''
      );
    };
  };
}
