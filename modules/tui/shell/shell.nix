{ config, ... }:
{
  home.shellAliases = {
    nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
  };
}
