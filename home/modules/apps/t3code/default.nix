{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.t3code;

  # T3 Code keeps its mutable state under <baseDir>/userdata, where baseDir
  # defaults to ~/.t3 (overridable via T3CODE_HOME). settings.json and
  # keybindings.json are read-modify-written by the server and the CLI, so they
  # cannot be store symlinks; themes/ is only read by the server.
  stateDir = cfg.stateDir;
  settingsFile = "${stateDir}/settings.json";
  keybindingsFile = "${stateDir}/keybindings.json";
  themesDir = "${stateDir}/themes";

  # T3CODE_HOME is the server's data root (defaults to ~/.t3) with userdata
  # stored underneath; `stateDir` is that userdata dir, so the service needs
  # its parent. Passing it explicitly keeps --base-dir/--state-dir overrides in
  # sync between the activation and the service.
  baseDir = builtins.dirOf stateDir;

  jq = lib.getExe pkgs.jq;

  # settings/keybindings can be given inline or as a path to a JSON file (e.g. a
  # copy of ~/.t3/userdata/settings.json); the *File variant wins when set.
  settingsValue =
    if cfg.settingsFile != null then
      builtins.fromJSON (builtins.readFile cfg.settingsFile)
    else
      cfg.settings;

  keybindingsValue =
    if cfg.keybindingsFile != null then
      builtins.fromJSON (builtins.readFile cfg.keybindingsFile)
    else
      cfg.keybindings;

  hasSettings = cfg.settingsFile != null || cfg.settings != { };
  hasKeybindings = cfg.keybindingsFile != null || cfg.keybindings != [ ];

  settingsJson = pkgs.writeText "t3code-settings.json" (builtins.toJSON settingsValue);
  keybindingsJson = pkgs.writeText "t3code-keybindings.json" (builtins.toJSON keybindingsValue);

  copyThemes = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: src: ''
      install -Dm644 ${src} ${lib.escapeShellArg "${themesDir}/${name}.json"}
    '') cfg.themes
  );
in
{
  options.custom.t3code = {
    enable = lib.mkEnableOption "declarative T3 Code theme, settings and keybinding sync";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../package/apps/t3code { };
      description = ''
        T3 Code package to install. Defaults to the repo's own nightly build
        (home/package/apps/t3code); override with pkgs.t3code or another build.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.t3/userdata";
      description = ''
        T3 Code userdata directory (holds settings.json, keybindings.json and
        themes/). Defaults to ~/.t3/userdata, i.e. the T3CODE_HOME default.
      '';
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Theme name -> JSON file. Each is copied to <stateDir>/themes/<name>.json
        on activation (copy, not symlink, so the in-app theme editor can still
        write; the next switch restores the declarative version).
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Keys merged into settings.json (recursive merge, declarative keys win).
        Mutually exclusive with `settingsFile`.
      '';
    };

    settingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a JSON file merged into settings.json (e.g. a copy of
        ~/.t3/userdata/settings.json). Takes precedence over `settings`.
      '';
    };

    keybindings = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      description = ''
        Keybinding rules merged into keybindings.json (declarative rules win per
        (key, when)). Mutually exclusive with `keybindingsFile`.
      '';
    };

    keybindingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a JSON file merged into keybindings.json (e.g. a copy of
        ~/.t3/userdata/keybindings.json). Takes precedence over `keybindings`.
      '';
    };

    service = {
      enable = lib.mkEnableOption "the T3 Code server as a systemd user service";

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = ''
          Interface the service binds to. Use "0.0.0.0" to make it reachable
          from other devices on the LAN/tailnet.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3773;
        description = ''
          Port for the service's HTTP/WebSocket server. Pinned (rather than the
          CLI's find-a-free-port default) so clients have a stable endpoint.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--tailscale-serve" ];
        description = "Extra arguments appended to `t3 serve`.";
      };

      restart = lib.mkOption {
        type = lib.types.str;
        default = "always";
        description = "systemd Restart= policy for the service.";
      };

      restartSec = lib.mkOption {
        type = lib.types.either lib.types.int lib.types.str;
        default = 5;
        description = "systemd RestartSec= delay for the service.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.settingsFile != null && cfg.settings != { });
        message = "custom.t3code: set either `settings` or `settingsFile`, not both.";
      }
      {
        assertion = !(cfg.keybindingsFile != null && cfg.keybindings != [ ]);
        message = "custom.t3code: set either `keybindings` or `keybindingsFile`, not both.";
      }
    ];

    home.packages = [ cfg.package ];

    # Declarative replacement for upstream's `t3 service install`. Upstream's
    # command downloads its own pinned server runtime into ~/.t3/runtime and
    # writes a unit that execs it; on NixOS we run the store-provided `t3`
    # instead. T3_BOOT_SERVICE_UNIT is intentionally NOT set: without it the
    # server reports no self-update capability, so clients ask the user to
    # update through the Nix config rather than launching `t3 update`.
    #
    # NOTE: a systemd *user* service only starts at boot when the user manager
    # is lingering (NixOS `users.users.<name>.linger = true`, equivalent to
    # `loginctl enable-linger`). Otherwise it starts at first login.
    systemd.user.services.t3code = lib.mkIf cfg.service.enable {
      Unit = {
        Description = "T3 Code server";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        Environment = [ "T3CODE_HOME=${baseDir}" ];
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/t3"
            "serve"
            "--host"
            cfg.service.host
            "--port"
            (toString cfg.service.port)
          ]
          ++ cfg.service.extraArgs
        );
        KillMode = "mixed";
        OOMPolicy = "continue";
        Restart = cfg.service.restart;
        RestartSec = cfg.service.restartSec;
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.activation.t3code = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.optionalString (cfg.themes != { }) ''
        mkdir -p ${lib.escapeShellArg themesDir}
        ${copyThemes}
      ''}

      ${lib.optionalString hasSettings ''
        if [ -f ${lib.escapeShellArg settingsFile} ]; then
          ${jq} -s '.[0] * .[1]' ${lib.escapeShellArg settingsFile} ${settingsJson} > ${lib.escapeShellArg settingsFile}.tmp
          mv ${lib.escapeShellArg settingsFile}.tmp ${lib.escapeShellArg settingsFile}
        else
          install -Dm644 ${settingsJson} ${lib.escapeShellArg settingsFile}
        fi
      ''}

      ${lib.optionalString hasKeybindings ''
        if [ -f ${lib.escapeShellArg keybindingsFile} ]; then
          ${jq} -s '.[1] + .[0] | unique_by([.key, (.when // "")])' ${lib.escapeShellArg keybindingsFile} ${keybindingsJson} > ${lib.escapeShellArg keybindingsFile}.tmp
          mv ${lib.escapeShellArg keybindingsFile}.tmp ${lib.escapeShellArg keybindingsFile}
        else
          install -Dm644 ${keybindingsJson} ${lib.escapeShellArg keybindingsFile}
        fi
      ''}
    '';
  };
}
