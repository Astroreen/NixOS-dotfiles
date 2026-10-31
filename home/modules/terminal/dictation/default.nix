{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.dictation;
  system = pkgs.stdenv.hostPlatform.system;

  # CUDA-enabled CTranslate2 (faster-whisper backend), module-local override.
  ctCuda = pkgs.ctranslate2.override {
    withCUDA = true;
    withCuDNN = true;
  };

  pythonEnv =
    (pkgs.python3.override {
      packageOverrides = _: prev: {
        ctranslate2 = prev.ctranslate2.override { ctranslate2-cpp = ctCuda; };
      };
    }).withPackages
      (ps: [
        ps.faster-whisper
        ps.fastapi
        ps.uvicorn
        ps.python-multipart
      ]);

  serverBin = pkgs.writeShellScript "faster-whisper-server" ''
    export FW_MODEL=${lib.escapeShellArg cfg.modelPath}
    export FW_MODEL_REPO=${lib.escapeShellArg cfg.modelRepo}
    export FW_DEVICE=${lib.escapeShellArg cfg.device}
    export FW_COMPUTE_TYPE=${lib.escapeShellArg cfg.computeType}
    export FW_HOST=${lib.escapeShellArg cfg.host}
    export FW_PORT=${toString cfg.port}
    export FW_IDLE_UNLOAD=${toString (cfg.server.idleUnloadMinutes * 60)}
    export FW_IDLE_EXIT=${toString (cfg.server.idleExitMinutes * 60)}
    exec ${pythonEnv}/bin/python ${./server.py}
  '';

  localUrl = "http://127.0.0.1:${toString cfg.port}/inference";
  remoteUrl = "http://${toString cfg.remote.host}:${toString cfg.remote.port}/inference";
  serverUrl = if cfg.mode == "remote" then remoteUrl else localUrl;

  daemonBin = pkgs.writeShellScript "dictation-daemon" ''
    export FW_SERVER_URL=${lib.escapeShellArg serverUrl}
    ${lib.optionalString (cfg.mode == "auto") ''
      export FW_MODE=auto
      export FW_LOCAL_URL=${lib.escapeShellArg localUrl}
      export FW_REMOTE_URL=${lib.escapeShellArg (lib.optionalString (cfg.remote.host != null) remoteUrl)}
      export FW_MAX_LATENCY_MS=${toString cfg.auto.maxLatencyMs}
    ''}
    export FW_LANGUAGE=${lib.escapeShellArg cfg.language}
    export FW_CAPTURE_SOURCE=${lib.escapeShellArg cfg.captureSource}
    export FW_STATE_FILE=/run/user/$(id -u)/dictation.state
    export FW_SOCKET=/run/user/$(id -u)/dictation.sock
    exec ${pythonEnv}/bin/python ${./daemon.py} "$@"
  '';

  # writeShellScript produces a bare file; wrap it so it can be installed into
  # the profile as `dictation-daemon` (the control client).
  daemonCli = pkgs.runCommand "dictation-daemon-cli" { } ''
    install -d $out/bin
    ln -s ${daemonBin} $out/bin/dictation-daemon
  '';

  # cava must read the default *source* (microphone). Its `auto` value follows
  # the default sink monitor instead, so the meter would show playback.
  cavaSource = if cfg.captureSource == "" then "@DEFAULT_SOURCE@" else cfg.captureSource;
  cavaConf = pkgs.writeText "dictation-cava.conf" ''
    [general]
    framerate = 30
    bars = 1

    [input]
    method = pipewire
    source = ${cavaSource}
    autosens = 0

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 100
    bit_format = 8bit
    channels = mono
    bar_delimiter = 59
  '';

  quickshell = inputs.quickshell.packages.${system}.default;
in
{
  options.custom.dictation = {
    enable = lib.mkEnableOption "push-to-talk voice dictation (faster-whisper)";

    mode = lib.mkOption {
      type = lib.types.enum [
        "local"
        "remote"
        "auto"
      ];
      default = "local";
      description = ''
        Where recordings are transcribed: `local` runs the server on this
        machine, `remote` sends them to `remote.host:remote.port` (another
        machine's server, e.g. one with a bigger GPU). `auto` picks per
        utterance: remote when it is reachable and either on battery or within
        `auto.maxLatencyMs`, else the local server, started on demand (set
        `server.idleExitMinutes` so it exits again and frees the GPU).
      '';
    };

    auto.maxLatencyMs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 150;
      description = ''
        `auto` mode on AC power: use the remote server only if its health
        check answers within this many milliseconds. On battery any answer
        (up to 1.5 s) wins, to keep the local GPU asleep.
      '';
    };

    remote = {
      host = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "gpu-box.example.ts.net";
        description = "Host of the transcription server used in `remote` mode.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 7777;
        description = "Port of the transcription server used in `remote` mode.";
      };
    };

    server.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable && cfg.mode != "remote";
      defaultText = lib.literalExpression ''config.custom.dictation.enable && config.custom.dictation.mode != "remote"'';
      description = ''
        Run the transcription server (`whisper-server` user service). Can be
        enabled alone to serve other machines without the dictation client.
      '';
    };

    server.idleUnloadMinutes = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      example = 10;
      description = ''
        Free the model's VRAM after this many idle minutes (0: keep it loaded).
        The next request reloads it, adding about a second.
      '';
    };

    server.idleExitMinutes = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      example = 5;
      description = ''
        Stop the server after this many idle minutes (0: keep running). Unlike
        `idleUnloadMinutes` this also drops the CUDA context, which a laptop
        dGPU needs to power off. `auto` mode starts it again when needed.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the transcription server binds to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7777;
      description = "HTTP port; keep 7777 for whisper.cpp drop-in compatibility.";
    };

    modelPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/astroreen/.local/share/faster-whisper-large-v3";
      description = "Local directory holding the CTranslate2 model.";
    };

    modelRepo = lib.mkOption {
      type = lib.types.str;
      default = "Systran/faster-whisper-large-v3";
      description = "HuggingFace repo used to populate modelPath when missing.";
    };

    device = lib.mkOption {
      type = lib.types.str;
      default = "cuda";
    };

    computeType = lib.mkOption {
      type = lib.types.str;
      default = "float16";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = "Default dictation language (auto = detect).";
    };

    daemonBin = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = ''
        Control client for the dictation daemon (start/stop/toggle/status).
        Consumed by window-manager integrations, e.g. the Hyprland binds.
      '';
    };

    captureSource = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "pw-record --target value; empty selects the default source.";
    };

    enableOverlay = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable || cfg.server.enable) {
    assertions = [
      {
        assertion = !cfg.enable || cfg.mode == "local" || cfg.remote.host != null;
        message = "custom.dictation.mode = \"${cfg.mode}\" needs custom.dictation.remote.host.";
      }
    ];

    home.packages = lib.mkIf cfg.enable (
      with pkgs;
      [
        wtype
        wl-clipboard
        cava
        material-symbols # overlay icons ("Material Symbols Outlined")
        daemonCli # control client: dictation-daemon start|stop|toggle|status
      ]
    );

    custom.dictation.daemonBin = daemonBin;

    systemd.user.services = {
      whisper-server = lib.mkIf cfg.server.enable {
        Unit = {
          Description = "faster-whisper transcription server (whisper.cpp drop-in)";
        };
        Service = {
          ExecStart = serverBin;
          Restart = "on-failure";
          RestartSec = "3s";
          # Hidden from sessions by custom.power.hybridGpu on the laptop
          UnsetEnvironment = [ "CUDA_VISIBLE_DEVICES" ];
        };
        # `auto` starts it on demand
        Install.WantedBy = lib.mkIf (cfg.mode != "auto") [ "default.target" ];
      };

      dictation = lib.mkIf cfg.enable {
        Unit = {
          Description = "Push-to-talk dictation daemon";
          After = [
            "graphical-session.target"
            "whisper-server.service"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = daemonBin;
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      dictation-overlay = lib.mkIf (cfg.enable && cfg.enableOverlay) {
        Unit = {
          Description = "Dictation Quickshell overlay";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${quickshell}/bin/qs -c dictation-overlay";
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };

    home.activation.dictationOverlay = lib.mkIf cfg.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        install -Dm644 ${./overlay/shell.qml} ${config.home.homeDirectory}/.config/quickshell/dictation-overlay/shell.qml
        install -Dm644 ${cavaConf} ${config.home.homeDirectory}/.config/quickshell/dictation-overlay/cava.conf
      ''
    );
  };
}
