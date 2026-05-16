{ pkgs, ... }:
let
  vscodeSettings = import ./settings.nix;
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

  wayland.windowManager.hyprland.settings.windowrule = [
    "match:class ^(Code)$, center on, float on" # Always center VSCode and it's notifications
  ];
}
