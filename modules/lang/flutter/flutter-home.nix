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
      "ANDROID_EMULATOR_FORCE_GPU" = "swiftshader_indirect";
      "QT_QPA_PLATFORM" = "xcb";
    };
    # Instruct the Flutter extension to start the emulator with ANGLE
    "dart.flutterEmulatorLaunchArgs" = [
      "-gpu"
      "swiftshader_indirect"
    ];
  };

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.1";
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
    abiVersions = [ "x86_64" ];
    includeEmulator = true;
    emulatorVersion = "35.1.4";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    includeSources = false;
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };
  androidSdk = androidComposition.androidsdk;
  sdkHome = "${config.home.homeDirectory}/Android/Sdk";
  cmdlineToolsVersion = "19.0"; # adjust if your version changes
  nixCmdlineTools = "${androidSdk}/libexec/android-sdk/cmdline-tools/${cmdlineToolsVersion}";
in
{
  home.packages = with pkgs; [
    flutter
    androidSdk
    android-tools
    firebase-tools
  ];

  # Symlink ~/Android/Sdk/cmdline-tools/latest -> $nixCmdlineTools
  # home.file."Android/Sdk".source = "${androidSdk}/libexec/android-sdk";
  home.activation.createAndroidSdkDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -rf "$HOME/Android/Sdk"
    mkdir -p "$HOME/Android/Sdk/cmdline-tools"
    ln -sf "${androidSdk}/libexec/android-sdk/build-tools" "$HOME/Android/Sdk/build-tools"
    ln -sf "${androidSdk}/libexec/android-sdk/cmdline-tools/${cmdlineToolsVersion}" "$HOME/Android/Sdk/cmdline-tools/latest"
    ln -sf "${androidSdk}/libexec/android-sdk/licenses" "$HOME/Android/Sdk/licenses"
    ln -sf "${androidSdk}/libexec/android-sdk/emulator" "$HOME/Android/Sdk/emulator"
    ln -sf "${androidSdk}/libexec/android-sdk/platforms" "$HOME/Android/Sdk/platforms"
    ln -sf "${androidSdk}/libexec/android-sdk/platform-tools" "$HOME/Android/Sdk/platform-tools"

    ln -sf "${androidSdk}/libexec/android-sdk/tools" "$HOME/Android/Sdk/tools"
    ln -sf "${androidSdk}/libexec/android-sdk/cmake" "$HOME/Android/Sdk/cmake"
    ln -sf "${androidSdk}/libexec/android-sdk/system-images" "$HOME/Android/Sdk/system-images"

  '';

  # VSCode settings (unchanged)
  programs.vscode.profiles.default.userSettings = existingSettings // flutterSettings;

  # Set environment variables to point to user-writable SDK
  home.sessionVariables = {
    ANDROID_SDK_ROOT = sdkHome;
    ANDROID_HOME = sdkHome;
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
    CHROME_EXECUTABLE = "${pkgs.vivaldi}/bin/vivaldi";
    # Android Emulator on NixOS/Wayland/NVIDIA tweaks
    ANDROID_EMULATOR_USE_SYSTEM_LIBS = "1"; # use system GL/Vulkan/Qt instead of bundled
  };

  programs.bash.sessionVariables = config.home.sessionVariables;
  programs.zsh.sessionVariables = config.home.sessionVariables;

  home.sessionPath = [
    "$HOME/Android/emulator-wrapper/bin" # wrapper first so VS Code uses it
    "${sdkHome}/cmdline-tools/latest/bin"
    "${sdkHome}/platforms"
    "${sdkHome}/platform-tools"
    "${sdkHome}/emulator"
    "${sdkHome}/tools"
    "${sdkHome}/tools/bin"
    "$HOME/.pub-cache/bin"
  ];

  # VS Code and Flutter extensions often call `emulator` directly.
  # Provide a wrapper that sets the required environment without affecting the whole system.
  home.file."Android/emulator-wrapper/bin/emulator" = {
    text = ''
      #!/usr/bin/env bash
      # NixOS/Wayland-friendly Android Emulator wrapper
      # Ensure emulator uses system GL/Vulkan/Qt and NVIDIA ICD
      export ANDROID_EMULATOR_USE_SYSTEM_LIBS=1
      export QT_QPA_PLATFORM=xcb
      export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"

      # If no GPU flag passed, default to angle_indirect (works on this host)
      if ! printf '%s\n' "$@" | grep -q -- '-gpu'; then
        set -- -gpu angle_indirect "$@"
      fi

      exec "$HOME/Android/Sdk/emulator/emulator" "$@"
    '';
    executable = true;
  };
}
