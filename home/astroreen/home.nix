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

    home.packages = with pkgs; [
        kdePackages.breeze      # For breeze cursor
    ];

    # Add cursor configuration
    home.pointerCursor = {
        name = "breeze_cursors";
        package = pkgs.kdePackages.breeze;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
    };

    home.sessionVariables = {
        "XCURSOR_THEME, breeze_cursors"
        "XCURSOR_SIZE, 24"
    };

    hyprland = {
        binds = import ./hyprland-binds.nix;

        waybar.enable = false;
        hyprpaper = {
            enable = false;
            wallpaper = ./assets/astronaut.jpg;
        };

        caelestia = {
            enable = true;
            wallpapers = ./assets/astronaut.jpg;
            avatar = ./assets/avatar.jpg;

            # All config options could be found here: https://github.com/caelestia-dots/shell/tree/main/config
            # or you could take a look at my caelestia shell.json file and tweak it to your liking.
            shell-file = ./assets/caelestia-shell-config.json;
        };
    };

    home.stateVersion = "25.05";
}
