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

    # Keyboard settings for wayland
    wayland.windowManager.hyprland.settings.input = {
        kb_layout = "us,ru,lt";
        kb_variant = ",phonetic,us";
        kb_options = "grp:win_space_toggle,grp:alt_shift_toggle"; # Win + Space to switch layouts

        follow_mouse = 1;

        touchpad = {
            natural_scroll = true;
        };
        
        sensitivity = 0;
    };

    hyprland = {
        binds = import ./hyprland-binds.nix;

        waybar.enable = false;
        hyprpaper = {
            enable = false;
            wallpaper = ./astronaut.jpg;
        };

        caelestia = {
            enable = true;
            wallpapers = ./astronaut.jpg;
            avatar = ./avatar.jpg;
        };
    };

    home.stateVersion = "25.05";
}
