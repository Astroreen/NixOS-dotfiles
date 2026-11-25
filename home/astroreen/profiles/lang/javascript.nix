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
    pnpm # default package manager; npm (bundled with node) stays as a fallback
    bun
    jq # JSON processor
  ];

  # Global installs (`pnpm add -g`) put their binaries in $PNPM_HOME/bin (pnpm >= 11)
  home.sessionVariables.PNPM_HOME = "$HOME/.local/share/pnpm";
  home.sessionPath = [ "$HOME/.local/share/pnpm/bin" ];

  programs.vscode.profiles.default.userSettings = javascriptSettings;
}
