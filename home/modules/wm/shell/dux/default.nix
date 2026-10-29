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
      session = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Default dux session state (weather, terminal, locale, wallpapers,
          night mode, pinned apps, display layout, ...), merged into the
          writable ~/.local/state/dms/session.json like `settings`.
        '';
      };
      pluginSettings = mkOption {
        type = types.attrsOf (types.attrsOf types.anything);
        default = { };
        description = ''
          Plugin settings keyed by plugin id, merged into
          ~/.config/dms/plugin_settings.json on top of each `plugins.<id>.settings`,
          like `settings`.
        '';
      };
      overrideSettings = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether `settings`, `session` and plugin settings win over values
          already in the live files (e.g. saved from the shell's settings UI).
          Off: they only fill keys the files do not have yet. Keys only the
          files have are kept either way.
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
          # Empty unless `dms setup` writes dux's stock binds; only required
          # so the Keybinds page finds its include (no "First Time Setup")
          "binds"
          "binds-user"
        ];
        description = ''
          Fragments of ~/.config/hypr/dms/ that dux writes from its settings UI
          (displays, keybind overrides, layout, ...), each `require`d at the end
          of hyprland.lua. Dux would append these lines itself, which fails on
          the read-only home-manager hyprland.lua. Empty disables it.
        '';
      };
      plugins = mkOption {
        default = { };
        description = ''
          Dux plugins, keyed by plugin id (`id` in plugin.json). Each `src` is
          linked to ~/.config/dms/plugins/<id> and the plugin is enabled in the
          writable ~/.config/dms/plugin_settings.json, so plugin settings stay
          editable in the UI. Pin sources by rev + hash and review the code:
          plugins run with your full privileges.
        '';
        type = types.attrsOf (
          types.submodule {
            options = {
              src = mkOption {
                type = types.either types.package types.path;
                description = "Plugin directory (the one holding plugin.json).";
              };
              settings = mkOption {
                type = types.attrsOf types.anything;
                default = { };
                description = "Default plugin settings; values saved from the UI win, like `settings`.";
              };
            };
          }
        );
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      # QML patch: player names come from desktop entries, so an app
      # reporting its app id as MPRIS identity still shows a readable name.
      # Go patch: `dms screenshot` rotated already-rotated Hyprland 0.57
      # screencopy frames again, turning 90/270 degree monitors sideways.
      package = inputs.dux-shell.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./screencopy-transform.patch ];
        postInstall = old.postInstall + ''
          patch -d $out/share/quickshell/dms -p1 < ${./mpris-display-name.patch}
        '';
      });
      quickshell.package = cfg.quickshellPackage;
      systemd.enable = true;
      # Keep empty so the upstream module does not symlink read-only
      # settings.json; `settings` merges into a mutable copy instead.
      settings = { };
      plugins = lib.mapAttrs (_: plugin: { inherit (plugin) src; }) cfg.plugins;
      # The upstream module would symlink a read-only plugin_settings.json;
      # duxPluginSettings below merges into a writable one instead.
      managePluginSettings = false;
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

      duxSession = lib.mkIf (cfg.session != { }) (
        shellLib.mkJsonConfigActivation {
          path = "${config.xdg.stateHome}/dms/session.json";
          defaults = cfg.session;
          overrideDefaults = cfg.overrideSettings;
          service = "dms";
        }
      );

      duxPluginSettings = lib.mkIf (cfg.plugins != { } || cfg.pluginSettings != { }) (
        shellLib.mkJsonConfigActivation {
          path = "${config.xdg.configHome}/dms/plugin_settings.json";
          defaults = lib.recursiveUpdate (lib.mapAttrs (
            _: plugin: { enabled = true; } // plugin.settings
          ) cfg.plugins) cfg.pluginSettings;
          overrideDefaults = cfg.overrideSettings;
          service = "dms";
          # Restart only once the plugin dirs are linked: dux watches
          # ~/.config/dms/plugins only if it existed when the shell started.
          after = [ "linkGeneration" ];
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
