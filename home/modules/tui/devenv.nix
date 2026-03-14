{
  pkgs,
  config,
  ...
}:
let
  # Direnv-specific settings to add to vscode
  direnvSettings = {
    # Direnv integration
    "direnv.restart.automatic" = true;
    "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
  };
in
{
  home.packages = with pkgs; [
    devenv
  ];

  programs = {
    direnv = {
      enable = true;
      package = pkgs.direnv;
      enableBashIntegration = true;
      enableFishIntegration = false;
      enableZshIntegration = true;
      enableNushellIntegration = false;
      silent = true;
      nix-direnv.enable = true;
      mise.enable = false;
    };

    vscode.profiles.default.userSettings = direnvSettings;
  };

  home.shellAliases = {
    # Alias to open the current directory in a Devenv shell
    dshell = "devenv shell";
    ds = "devenv shell";
    dv = "devenv";
  };
}
