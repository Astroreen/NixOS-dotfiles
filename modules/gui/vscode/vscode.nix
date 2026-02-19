{ pkgs, lib, ... }:
let
  vscodeSettings = import ./settings.nix;

  # dynamicSettings = {};
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      userSettings = vscodeSettings; # // dynamicSettings;
      enableUpdateCheck = false;
    };
  };

  home.packages = with pkgs; [ nixfmt ]; # format Nix files
}
