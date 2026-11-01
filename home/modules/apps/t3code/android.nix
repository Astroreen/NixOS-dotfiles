# Android emulator for T3 Code's device tools (Device panel, device_open, ...),
# scoped to the T3 service: nothing lands on the user's PATH or in the session
# environment.
#
# T3 picks the SDK from ANDROID_HOME (else ~/Android/Sdk), puts its
# platform-tools/ and emulator/ first on the device hub's PATH, and checks for
# an ffmpeg with libx264 before it opens an emulator (SERVE_EMU_FFMPEG, else
# `ffmpeg` on PATH). Both variables point at stable links under <baseDir>, so a
# new SDK or ffmpeg only moves the links; the unit, and T3's running process,
# keep their environment.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.t3code;
  acfg = cfg.android;

  baseDir = builtins.dirOf cfg.stateDir;
  linkDir = "${baseDir}/android";
  sdkLink = "${linkDir}/sdk";
  ffmpegLink = "${linkDir}/ffmpeg";

  composed = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ acfg.platformVersion ];
    buildToolsVersions = [ ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ acfg.systemImageType ];
    abiVersions = [ acfg.abi ];
    includeNDK = false;
    includeCmake = false;
    toolsVersion = null;
  };

  # androidenv keeps the SDK under libexec/android-sdk with cmdline-tools/<ver>;
  # T3 (and Android Studio's layout) expect cmdline-tools/latest for avdmanager.
  sdkRoot = pkgs.runCommand "t3code-android-sdk" { } ''
    src=${composed.androidsdk}/libexec/android-sdk
    mkdir -p $out/cmdline-tools
    for entry in "$src"/*; do
      [ "$(basename "$entry")" = cmdline-tools ] || ln -s "$entry" $out/
    done
    for entry in "$src"/cmdline-tools/*; do
      ln -s "$entry" $out/cmdline-tools/
    done
    if [ ! -e $out/cmdline-tools/latest ]; then
      ln -s "$(ls -d "$src"/cmdline-tools/* | sort -V | tail -n1)" $out/cmdline-tools/latest
    fi
  '';

  systemImage = "system-images;android-${acfg.platformVersion};${acfg.systemImageType};${acfg.abi}";

  # avdmanager answers "no" to its custom hardware profile prompt on stdin.
  createAvd = pkgs.writeShellScript "t3code-create-avd" ''
    echo no | ${sdkRoot}/cmdline-tools/latest/bin/avdmanager create avd \
      --name "$1" --package ${lib.escapeShellArg systemImage} --device "$2"
  '';

  # Only for AVDs that do not exist yet: an existing AVD (and its data
  # partition) is never touched.
  createAvds = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: avd: ''
      if [ ! -e "$avdHome"/${lib.escapeShellArg name}.ini ]; then
        verboseEcho "t3code: creating AVD ${name}"
        run ${createAvd} ${lib.escapeShellArg name} ${lib.escapeShellArg avd.device} \
          || errorEcho "t3code: avdmanager failed for AVD ${name}"
      fi
    '') acfg.avds
  );
in
{
  options.custom.t3code.android = {
    enable = lib.mkEnableOption ''
      the Android emulator for T3 Code's device tools: an Android SDK with the
      emulator and a system image, and ffmpeg with libx264, given to the T3
      service only (ANDROID_HOME, SERVE_EMU_FFMPEG)
    '';

    platformVersion = lib.mkOption {
      type = lib.types.str;
      default = "36";
      description = "Android platform (API level) of the SDK platform and system image.";
    };

    systemImageType = lib.mkOption {
      type = lib.types.str;
      default = "google_apis";
      description = "System image flavour (default, google_apis, google_apis_playstore, ...).";
    };

    abi = lib.mkOption {
      type = lib.types.str;
      default = "x86_64";
      description = "System image ABI; x86_64 runs on KVM without translation.";
    };

    ffmpeg = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ffmpeg-headless;
      description = ''
        ffmpeg that streams the emulator to the Device panel. Must include the
        libx264 encoder (nixpkgs' ffmpeg-headless does).
      '';
    };

    avds = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.device = lib.mkOption {
            type = lib.types.str;
            default = "pixel_7";
            description = "avdmanager hardware profile (`avdmanager list device`).";
          };
        }
      );
      default = { };
      example = {
        pixel-36 = { };
      };
      description = ''
        AVDs created on activation in ~/.android/avd (ANDROID_AVD_HOME) from the
        system image, when missing. Existing AVDs are left alone.
      '';
    };

    sdk = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = sdkRoot;
      description = "The composed SDK root that ANDROID_HOME points at (through a stable link).";
    };
  };

  config = lib.mkIf (cfg.enable && acfg.enable) {
    # Links under <baseDir>/android (~/.t3/android), moved on every switch.
    home.file = {
      "${lib.removePrefix "${config.home.homeDirectory}/" sdkLink}".source = sdkRoot;
      "${lib.removePrefix "${config.home.homeDirectory}/" ffmpegLink}".source =
        lib.getExe' acfg.ffmpeg "ffmpeg";
    };

    systemd.user.services.t3code = lib.mkIf cfg.service.enable {
      Service.Environment = [
        "ANDROID_HOME=${sdkLink}"
        "SERVE_EMU_FFMPEG=${ffmpegLink}"
      ];
    };

    home.activation.t3codeAndroidAvds = lib.mkIf (acfg.avds != { }) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        avdHome="''${ANDROID_AVD_HOME:-''${ANDROID_USER_HOME:-$HOME/.android}/avd}"
        run mkdir -p "$avdHome"
        ${createAvds}
      ''
    );
  };
}
