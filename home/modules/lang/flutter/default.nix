# Flutter Development Environment for NixOS
#
# This module sets up Flutter with Android SDK support for NixOS.
#
# WHY THE COMPLEXITY?
# - Android SDK components are scattered across the Nix store
# - Flutter/Android tools expect a unified SDK structure at $ANDROID_SDK_ROOT
# - We create symlinks from ~/Android/Sdk to the Nix store components
# - This allows adb (Android Debug Bridge) and other tools to find everything
#
# WHAT DOES THIS CONFIGURE?
# - Flutter SDK with Android support
# - Android SDK with required platforms and build tools
# - Android Emulator with hardware acceleration (via KVM)
# - VSCode settings for Flutter development
# - Environment variables for Android tools
#
{
  lib,
  config,
  pkgs,
  ...
}:
let

  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
  existingSettings =
    if builtins.pathExists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

  flutterSettings = {
    # Point Flutter extension at the immutable Nix store SDK; VS Code only reads from it.
    "dart.flutterSdkPath" = "${pkgs.flutter}";
    # Dart SDK path (inside the Flutter SDK) so the Dart extension is happy.
    "dart.sdkPaths" = [ "${pkgs.flutter}/bin/cache/dart-sdk" ];
    "dart.devToolsBrowser" = "default";
    "dart.flutterCreateAndroidLanguage" = "java";
    "dart.hotReloadOnSave" = "manual";
    # Ensure Flutter/Dart/Android tools launched by the VS Code extension see the right env
    "dart.env" = {
      "ANDROID_SDK_ROOT" = sdkHome;
      "ANDROID_HOME" = sdkHome;
      "ANDROID_EMULATOR_USE_SYSTEM_LIBS" = "1";
      "ANDROID_EMULATOR_FORCE_ANGLE" = "false";
      "ANDROID_EMULATOR_FORCE_GPU" = "angle_indirect";
      "QT_QPA_PLATFORM" = "xcb";
    };
    # Instruct the Flutter extension to start the emulator with ANGLE
    "dart.flutterEmulatorLaunchArgs" = [
      "-gpu"
      "angle_indirect"
    ];

    "dart.flutterRunAdditionalArgs" = [
      "--no-enable-impeller" # Disable Impeller renderer for better compatibility on this host
    ];
  };

  includeAuto = pkgs.stdenv.hostPlatform.isx86_64 || pkgs.stdenv.hostPlatform.isDarwin;

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    includeNDK = true;
    includeEmulator = true;
    includeSystemImages = true;
    includeSources = false;
    useGoogleAPIs = true;
    useGoogleTVAddOns = true;

    abiVersions = [ "x86_64" ];
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.1";
    emulatorVersion = "35.1.4";
    cmakeVersions = [ "3.22.1" ];
    ndkVersions = [
      "23.1.7779620"
      "25.1.8937393"
      "26.1.10909125"
      "28.2.13676358"
      "latest"
    ];
    buildToolsVersions = [
      "28.0.3" # Required by Flutter
      "30.0.3"
      "33.0.1"
      "34.0.0"
      "35.0.0"
    ];
    platformVersions = [
      "28" # For compatibility
      "31"
      "33"
      "34"
      "35"
      "36" # Required by Flutter
    ];

    includeExtras = [
      "extras;google;gcm"
    ]
    ++ pkgs.lib.optionals includeAuto [
      "extras;google;auto"
    ];

    systemImageTypes = [ "google_apis_playstore" ];

    extraLicenses = [
      # Already accepted for you with the global accept_license = true or
      # licenseAccepted = true on androidenv.
      # "android-sdk-license"

      # These aren't, but are useful for more uncommon setups.
      "android-sdk-preview-license"
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  sdkHome = "${config.home.homeDirectory}/Android/Sdk";

  cmdlineToolsVersion = "19.0"; # adjust if your version changes
in
{
  programs = {
    # VSCode settings (unchanged)
    vscode.profiles.default.userSettings = existingSettings // flutterSettings;
    bash.sessionVariables = config.home.sessionVariables;
    zsh.sessionVariables = config.home.sessionVariables;
  };

  home = {
    packages = with pkgs; [
      flutter
      androidSdk
      android-tools
      aapt
      # firebase-tools # Commenting out since it breaks configuration and this module is rarely used
    ];

    # VS Code and Flutter extensions often call `emulator` directly.
    # Provide a wrapper that sets the required environment without affecting the whole system.
    file."Android/emulator-wrapper/bin/emulator" = {
      text = ''
        #!/usr/bin/env bash
        # NixOS/Wayland-friendly Android Emulator wrapper
        # Ensure emulator uses system GL/Vulkan/Qt and NVIDIA ICD
        export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1
        export QT_QPA_PLATFORM=xcb
        export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"

        # If no GPU flag passed, default to angle_indirect (works on this host)
        if ! printf '%s\n' "$@" | grep -q -- '-gpu'; then
          set -- -gpu angle_indirect "$@"
        fi

        exec "${ANDROID_SDK_ROOT}/emulator/emulator" "$@"
      '';
      executable = true;
    };

    # Writing custom activation script all because emulator does not work propelly
    activation.createAndroidSdkDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -rf "${sdkHome}"
      mkdir -p "${sdkHome}/cmdline-tools"
      mkdir -p "${sdkHome}/emulator"

      ln -sf "${ANDROID_SDK_ROOT}/build-tools" "${sdkHome}/build-tools"
      ln -sf "${ANDROID_SDK_ROOT}/cmdline-tools/${cmdlineToolsVersion}" "${sdkHome}/cmdline-tools/latest"
      ln -sf "${ANDROID_SDK_ROOT}/licenses" "${sdkHome}/licenses"
      ln -sf "${ANDROID_SDK_ROOT}/platforms" "${sdkHome}/platforms"
      ln -sf "${ANDROID_SDK_ROOT}/platform-tools" "${sdkHome}/platform-tools"
      ln -sf "${ANDROID_SDK_ROOT}/ndk" "${sdkHome}/ndk"
      ln -sf "${ANDROID_SDK_ROOT}/tools" "${sdkHome}/tools"
      ln -sf "${ANDROID_SDK_ROOT}/cmake" "${sdkHome}/cmake"
      ln -sf "${ANDROID_SDK_ROOT}/system-images" "${sdkHome}/system-images"

      # Commenting out and using wrapper
      # ln -sf "${ANDROID_SDK_ROOT}/emulator" "${sdkHome}/emulator"
      # Emulator symlink for VS Code and Flutter tools that call it directly
      ln -sf "$HOME/Android/emulator-wrapper/bin/emulator" "${sdkHome}/emulator/emulator"
    '';

    # Set environment variables to point to user-writable SDK
    sessionVariables = {
      ANDROID_SDK_ROOT = sdkHome;
      ANDROID_HOME = sdkHome;
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${pkgs.aapt}/bin/aapt2";
      CHROME_EXECUTABLE = "${pkgs.vivaldi}/bin/vivaldi";
      # Android Emulator on NixOS/Wayland/NVIDIA tweaks
      ANDROID_EMULATOR_USE_SYSTEM_LIBS = "1"; # use system GL/Vulkan/Qt instead of bundled
    };

    sessionPath = [
      "$HOME/Android/emulator-wrapper/bin" # wrapper first so VS Code uses it
      "${sdkHome}/cmdline-tools/latest/bin"
      "${sdkHome}/platforms"
      "${sdkHome}/platform-tools"
      "${sdkHome}/emulator"
      "${sdkHome}/tools"
      "${sdkHome}/tools/bin"
      "$HOME/.pub-cache/bin"
    ];
  };
}
