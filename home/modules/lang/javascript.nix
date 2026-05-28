{
  pkgs,
  ...
}:
let
  node-package = pkgs.nodejs_24;

  javascriptSettings = {
    "sonarlint.pathToNodeExecutable" = "${node-package}/bin/node";

    # Disable path suggestions since we are using Path Intellisense
    "js/ts.suggest.paths" = false;

    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.tabSize" = 4;
    };

    "js/ts.format.enabled" = false;
  };
in
{
  home.packages = with pkgs; [
    node-package
    bun
  ];

  programs.vscode.profiles.default.userSettings = javascriptSettings;
}
