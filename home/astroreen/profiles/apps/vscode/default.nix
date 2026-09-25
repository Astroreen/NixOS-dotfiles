{ pkgs, config, ... }:
let
  vscodeSettings = import ./settings.nix;
in
{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "nixconfig-code" ''
      cd ${config.home.homeDirectory}/.local/share/nixos
      exec ${pkgs.vscode}/bin/code .
    '')
    nixfmt # format Nix files
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      userSettings = vscodeSettings; # // dynamicSettings;
      enableUpdateCheck = false;
    };
  };

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(Code)$";
      center = true;
      float = true;
    } # Always center VSCode and it's notifications
  ];

   xdg.desktopEntries.nixconfig = {
    name = "NixOS Config";
    genericName = "Editor";
    exec = "nixconfig-code";
    terminal = false;
    categories = [
      "Development"
      "IDE"
    ];
    icon = "vscode";
    comment = "Open the NixOS configuration project in VSCode";
  };
}
