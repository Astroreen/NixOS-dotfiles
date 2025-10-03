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
    "dart.flutterSdkPath" = "${pkgs.flutter}";
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
  sdkHome = "${config.home.homeDirectory}/Android/Sdk";
  cmdlineToolsVersion = "19.0"; # adjust if your version changes
  nixCmdlineTools = "${androidSdk}/libexec/android-sdk/cmdline-tools/${cmdlineToolsVersion}";
in
{
  home.packages = with pkgs; [
    flutter
    androidSdk
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
  };

  programs.bash.sessionVariables = config.home.sessionVariables;
  programs.zsh.sessionVariables = config.home.sessionVariables;

  home.sessionPath = [
    "${sdkHome}/cmdline-tools/latest/bin"
    "${sdkHome}/platforms"
    "${sdkHome}/platform-tools"
    "${sdkHome}/emulator"
    "${sdkHome}/tools"
    "${sdkHome}/tools/bin"
    "$HOME/.pub-cache/bin"
  ];
}
