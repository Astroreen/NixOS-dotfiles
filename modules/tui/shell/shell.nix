{ config, ... }:
{

  # Apply changes through home-manager and nixos system-wide configuration
  programs = {
    bash.enable = true;
    bash.enableCompletion = true;
  };
  
  home.shellAliases = {
    nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
  };
}
