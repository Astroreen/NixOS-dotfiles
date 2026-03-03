{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    package = pkgs.bat;
    extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
  };

  home.shellAliases = {
    cat = "bat";
  };
}
