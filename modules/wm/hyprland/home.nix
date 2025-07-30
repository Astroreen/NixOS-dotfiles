{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}: 

let 
    binds = import ./binds.nix;
in

{

    # Hyprland specific programs (they relevent only on Hyprland)
    programs = {
        waybar = {
            enable = true;
        };
    };

    # Configs to apply
    home.file = lib.mkMerge [
        {
            "/Pictures/Wallpapers/nixos-wallpaper.png" = {
                source = ./wallpaper.png;
            };
        }
        {
            ".config/waybar" = {
                source = ./waybar;
                recursive = true;
            };
        }
        {
            ".config/waybar/waybar.sh" = {
                source = ./waybar/waybar.sh;
                executable = true; # ensure script is executable
            };
        }
        {
            ".config/waybar/modules/mediaplayer.py" = {
                source = ./waybar/modules/mediaplayer.py;
                executable = true; # ensure script is executable
            };
        }
    ];

    # Setup wallpapers
    services.hyprpaper = {
        enable = true;
        settings = {
            preload = [
                "~/Pictures/Wallpapers/nixos-wallpaper.png"
            ];
            wallpaper = [
                ", ~/Pictures/Wallpapers/nixos-wallpaper.png"
            ];
        };
    };

    # Wayland settings
    wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
        systemd.variables = ["--all"];
    };

    # Hyprland settings
    wayland.windowManager.hyprland.settings = {

        # Monitors
        monitor = [
            # [Monitor][Resolution@Hz]0x0[Scale]
            ",auto,0x0,1" # Auto 
            # left
            # "DP-4,     1920x1080@60,  0x0,    1" 
            # center
            # "HDMI-A-1, 1920x1080@120, 1920x0, 1"
            # right
            # "eDP-1,    1920x1080@60,  3840x0, 1"
        ];

        # Keyboard settings
        input = {
            kb_layout = "us";
            kb_variant = "alt-intl";
            
            follow_mouse = 1;

            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

            touchpad = {
                natural_scroll = true;
            };

            numlock_by_default = true;
        };

        # Default programs definitions (used in keybinds and other places)
        "$terminal" = "kitty";
        "$fileManager" = "nautilus";
        "$menu" = "walker";
        "$mainMod" = "SUPER";
        "$code" = "codium";
        "$browser" = "chromium --incognito";
        "$editor" = "gnome-text-editor";

        # Commands to execute once on Hyprland start
        exec-once = [
            "sh ~/.config/waybar/waybar.sh"
            "hyprpaper"
            "wl-clip-persist"
            "power-profiles-daemon"
            "nm-applet --no-agent"
        ];

        # Windows rules
        windowrule = [
            "suppressevent maximize, class:.*"
            "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];

        # General settings
        general = {
            "$mainMod" = "SUPER"; # Main modification button (passed to binds file)
            layout = "dwindle";
            gaps_in = 1;
            gaps_out = 1;
            border_size = 1;
            resize_on_border = true;
        };

        # Binds
        bind = binds.bind;
        bindm = binds.bindm;
        bindl = binds.bindl;
        bindel = binds.bindel;

        # Session variables passed to hyprland
        # instead of system-level environment.sessionVariables
        env = [
            "NIXOS_OZONE_WL, 1"
            "GTK_THEME, Dark-Gruvbox" # required for Nautilus to apply current theme
            "XDG_SESSION_DESKTOP, Hyprland"
            "XDG_CURRENT_DESKTOP, Hyprland"
            "XDG_DESKTOP_DIR, $HOME/Desktop"
            "XDG_DOWNLOAD_DIR, $HOME/Downloads"
            "XDG_TEMPLATES_DIR, $HOME/Templates"
            "XDG_PUBLICSHARE_DIR, $HOME/Public"
            "XDG_DOCUMENTS_DIR, $HOME/Documents"
            "XDG_MUSIC_DIR, $HOME/Music"
            "XDG_PICTURES_DIR, $HOME/Pictures"
            "XDG_VIDEOS_DIR, $HOME/Videos"
            "HYPRSHOT_DIR, $HOME/Pictures/Screenshots"
        ];

        # Style
        decoration = {
            rounding = 5;

            active_opacity = 1.0;
            inactive_opacity = 0.99;
    
            shadow = {
                enabled = true;
                range = 4;
                render_power = 3;
                color = "rgba(1a1a1aee)";
            };

            blur = {
                enabled = true;
                size = 3;
                passes = 1;
                vibrancy = 0.1696;
            };
        };

        # Settings you probably don't want to change
        dwindle = {
            pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
            preserve_split = true; # You probably want this
        };

        misc = {
            force_default_wallpaper = 0; # Set to 1 to use the anime mascot wallpapers
            disable_hyprland_logo = true; # If true disables the random hyprland logo / anime girl background. :(
        };

        gestures = {
            workspace_swipe = true;
        };
    };
}