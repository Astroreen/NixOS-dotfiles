{
  lib,
  config,
  pkgs,
  ...
}:
let

  androidComposition = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.1";
    buildToolsVersions = [
      "30.0.3"
      "33.0.1"
      "34.0.0"
    ];
    platformVersions = [
      "31"
      "33"
      "34"
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

  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
  existingSettings =
    if builtins.pathExists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

  flutterSettings = {
    "dart.flutterSdkPaths" = [
      "${pkgs.flutter}"
    ];
    "dart.sdkPaths" = [
      "${pkgs.flutter}"
      "${androidSdk}"
      "${androidSdk}/libexec/android-sdk/platform-tools"
      "${androidSdk}/libexec/android-sdk/cmdline-tools/latest/bin"
      "${androidSdk}/libexec/android-sdk/emulator"
      "${androidSdk}/libexec/android-sdk/tools"
      "${androidSdk}/libexec/android-sdk/tools/bin"
    ];
    "dart.devToolsBrowser" = "default";
    "dart.flutterCreateAndroidLanguage" = "java";
    "dart.hotReloadOnSave" = "manual";
  };
in
{
  # Download flutter
  home.packages = with pkgs; [
    flutter
    androidSdk
    firebase-tools
    # java comes from lang.java
  ];

  # Apply flutter settings to vscode
  programs = {
    vscode = {
      profiles.default.userSettings = existingSettings // flutterSettings;
    };
  };

  home.sessionVariables = {
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
  };

  home.sessionPath = [
    "${androidSdk}"
    "${androidSdk}/libexec/android-sdk/platform-tools"
    "${androidSdk}/libexec/android-sdk/cmdline-tools/latest/bin"
    "${androidSdk}/libexec/android-sdk/emulator"
    "${androidSdk}/libexec/android-sdk/tools"
    "${androidSdk}/libexec/android-sdk/tools/bin"
    "$HOME/.pub-cache/bin"
  ];
}
