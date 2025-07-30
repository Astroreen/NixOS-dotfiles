{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}: {
    imports = [
        # Apps (gui)
        ../../modules/gui/apps

        # Terminal apps (tui)
        ../../modules/tui/kitty

        # Windows manager (wm)
        ../../modules/wm/hyprland/home.nix
    ];

    home.username = "astroreen";
    home.homeDirectory = "/home/astroreen";

    programs = {
        git = {
            enable = true;
            package = pkgs.git;
            userName = "astroreen";
            userEmail = "astroreen@gmail.com";

            #aliases = {
            #    commit = "commit -m ''";
            #};
        };

        vscode = {
            enable = true;
            package = pkgs.vscodium;
        };

        chromium = {
            enable = true;
            package = pkgs.chromium;
        };
    };

  home.stateVersion = "25.05";
}
