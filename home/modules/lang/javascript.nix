{
  pkgs,
  config,
  ...
}:
let
  node-package = pkgs.nodejs_24;
  settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";

  javascriptSettings = {
    "sonarlint.pathToNodeExecutable" = "${node-package}/bin/node";

    # Disable path suggestions since we are using Path Intellisense
    "typescript.suggest.paths" = false;
    "javascript.suggest.paths" = false;
  };
in
{
  home.packages = with pkgs; [ node-package bun ];

  programs.vscode.profiles.default.userSettings = javascriptSettings;
}
