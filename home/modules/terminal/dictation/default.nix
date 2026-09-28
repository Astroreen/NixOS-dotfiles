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
    exec ${pythonEnv}/bin/python ${./server.py}
  '';

  daemonBin = pkgs.writeShellScript "dictation-daemon" ''
    export FW_SERVER_URL=http://127.0.0.1:${toString cfg.port}/inference
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

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wtype
      wl-clipboard
      cava
      daemonCli # control client: dictation-daemon start|stop|toggle|status
    ];

    custom.dictation.daemonBin = daemonBin;

    systemd.user.services = {
      whisper-server = {
        Unit = {
          Description = "faster-whisper transcription server (whisper.cpp drop-in)";
        };
        Service = {
          ExecStart = serverBin;
          Restart = "on-failure";
          RestartSec = "3s";
        };
        Install.WantedBy = [ "default.target" ];
      };

      dictation = {
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

      dictation-overlay = lib.mkIf cfg.enableOverlay {
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

    home.activation.dictationOverlay = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      install -Dm644 ${./overlay/shell.qml} ${config.home.homeDirectory}/.config/quickshell/dictation-overlay/shell.qml
      install -Dm644 ${cavaConf} ${config.home.homeDirectory}/.config/quickshell/dictation-overlay/cava.conf
    '';
  };
}
