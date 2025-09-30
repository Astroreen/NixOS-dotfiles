{
  lib,
  config,
  pkgs,
  ...
}:
let
  flutterPackage = pkgs.flutter332;
  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";

  existingSettings =
    if builtins.pathExists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

  flutterSettings = {
    "dart.flutterSdkPaths" = [
      "${flutterPackage}"
      "${pkgs.android-studio-tools}"
      "${pkgs.android-tools}"
    ];
    "dart.sdkPaths" = [
      "${flutterPackage}"
      "${pkgs.android-studio-tools}"
      "${pkgs.android-tools}"
    ];
    "dart.devToolsBrowser" = "default";
    "dart.flutterCreateAndroidLanguage" = "java";
    "dart.hotReloadOnSave" = "manual";
  };
in
{
  # Download flutter
  home.packages = with pkgs; [
    flutterPackage
    android-studio
    android-studio-tools
    android-tools
  ];

  # Apply flutter settings to vscode
  programs = {
    vscode = {
      profiles.default.userSettings = existingSettings // flutterSettings;
    };
  };
}
