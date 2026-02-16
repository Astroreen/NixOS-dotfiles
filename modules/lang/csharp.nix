{
  pkgs,
  lib,
  config,
  ...
}:
let
  dotnetPackage = pkgs.dotnetCorePackages.sdk_9_0-bin;

  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
  existingSettings =
    if builtins.pathExists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

  csharpSettings = {
    "omnisharp.dotnetPath" = "${dotnetPackage}/bin/dotnet";
    "dotnet.dotnetPath" = "${dotnetPackage}/bin/dotnet";
    "dotnet.server.useOmnisharp" = false;
    "csharp.experimental.roslynDevKit" = true;
  };
in
{

  programs.vscode = {
    profiles.default.userSettings = existingSettings // csharpSettings;
  };

  home.packages = with pkgs; [
    dotnetPackage
    omnisharp-roslyn # Optional: strictly for the legacy C# extension
    netcoredbg # For debugging
  ];

  # Optional but recommended: system-wide fix for unpatched binaries
  # This helps VSCode's internal 'vsdbg' find its own libraries
  home.sessionVariables = {
    DOTNET_ROOT = "${dotnetPackage}";
  };
}
