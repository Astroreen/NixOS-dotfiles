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

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(Code)$";
      center = true;
      float = true;
    } # Always center VSCode and it's notifications
  ];
}
