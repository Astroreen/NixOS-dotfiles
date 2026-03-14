{
  pkgs,
  config,
  ...
}:
let
  dotnetPackage = pkgs.dotnetCorePackages.sdk_9_0-bin;

  csharpSettings = {
    "omnisharp.dotnetPath" = "${dotnetPackage}/bin/dotnet";
    "dotnet.dotnetPath" = "${dotnetPackage}/bin/dotnet";
    "dotnet.server.useOmnisharp" = false;
    "csharp.experimental.roslynDevKit" = true;
  };
in
{

  programs.vscode.profiles.default.userSettings = csharpSettings;

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
