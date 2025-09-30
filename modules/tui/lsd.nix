{ pkgs, ... }:
{
  programs.lsd = {
    enable = true;
    package = pkgs.lsd;
    enableBashIntegration = true;
  };
}
