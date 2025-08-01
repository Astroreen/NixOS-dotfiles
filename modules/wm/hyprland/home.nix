{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}: 

let 
    cfg = config.hyprland;
in

{
    options.hyprland = {
        binds = lib.mkOption {
            type = lib.types.attrs;
            default = import ./binds.nix;
            example = "hyprland.binds = import /absolute/path/to/binds.nix or ./relative/path/to/binds.nix";
            description = "Use this guide for flags: https://wiki.hypr.land/Configuring/Binds/#bind-flags";
        };

        waybar.enable = lib.mkEnableOption "Enable wayland - bar at the top";

        hyprpaper = {
            enable = lib.mkEnableOption "Set up wallpaper";

            wallpaper = lib.mkOption {
                type = lib.types.path;
                default = ./nixos-wallpaper.png;
                example = "/absolute/path/to/wallpaper.png or ./relative/path/to/wallpaper.jpg";
                description = "Path to wallpaper to set main wallpaper on screen";
            };
        };

        caelestia = {
            enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = "true";
                description = "A powerfull and seggsy looking shell";
            };

            wallpapers = lib.mkOption {
                type = lib.types.path;
                default = ./nixos-wallpaper.png;
                example = "/absolute/path/to/wallpaper.png or ./relative/path/to/wallpaper.jpg";
                description = "Path to wallpaper to set main wallpaper on screen";
            };

            avatar = lib.mkOption {
                type = lib.types.path;
                default = ./avatar;
                example = "/absolute/path/to/avatar.png or ./relative/path/to/avatar.jpg";
                description = "Path to avatar";
            };

            shell-file = lib.mkOption {
                type = lib.types.path;
                default = inputs.caelestia-shell + "/shell.json";
                example = "/absolute/path/to/shell.json or ./relative/path/to/shell.json";
                description = "Path to main quickshell configuration file";
            };
        };
    };

    config = {
        # Hyprland specific programs (they relevent only on Hyprland)
        programs = {
            waybar = {
                enable = cfg.waybar.enable;
            };
        };

        # Configs to apply
        home.file = {
            
        } 
        // lib.optionalAttrs cfg.hyprpaper.enable {
            "Pictures/Wallpapers/wallpaper.png" = {
                source = cfg.hyprpaper.wallpaper;
            };
        }
        // lib.optionalAttrs cfg.waybar.enable {
            ".config/waybar" = {
                source = ./waybar;
                recursive = true;
            };
            ".config/waybar/waybar.sh" = {
                source = ./waybar/waybar.sh;
                executable = true;
            };
            ".config/waybar/modules/mediaplayer.py" = {
                source = ./waybar/modules/mediaplayer.py;
                executable = true;
            };
        }
        // lib.optionalAttrs cfg.caelestia.enable {
            ".config/quickshell/caelestia".source = inputs.caelestia-shell;
            ".config/caelestia/shell.json".source = cfg.caelestia.shell-file;
            ".face".source = cfg.caelestia.avatar;
            ".local/state/caelestia/wallpaper/current".source = cfg.caelestia.wallpapers;
        };

        # Setup wallpapers
        services.hyprpaper = {
            enable = cfg.hyprpaper.enable;
            settings = {
                preload = [
                    "~/Pictures/Wallpapers/wallpaper.png"
                ];
                wallpaper = [
                    ", ~/Pictures/Wallpapers/wallpaper.png"
                ];
            };
        };

        # Create systemd service to run Caelestia shell
        systemd.user.services = lib.mkIf cfg.caelestia.enable {
            caelestia = {
                Unit = {
                    Description = "Caelestia Shell";
                    After = [ "hyprland-session.target" ];
                    BindsTo = [ "hyprland-session.target" ];
                    Requisite = [ "hyprland-session.target" ];
                };

                Service = {
                    Type = "simple";
                    ExecStart = "${inputs.quickshell.packages.${pkgs.system}.default}/bin/qs -c caelestia";
                    Restart = "on-failure";
                    RestartSec = "3s";
                    RestartPreventExitStatus = "0";
                    # Set environment variables for the service
                    Environment = [
                        "QT_QPA_PLATFORMTHEME=qt6ct"
                        "XDG_RUNTIME_DIR=/run/user/1000"
                    ];
                };

                Install = {
                    WantedBy = [ "hyprland-session.target" ];
                };
            };
        };

        home.packages = with pkgs; [
            kdePackages.dolphin
        ]
        ++ lib.optionals cfg.caelestia.enable [
            # Caelestia
            inputs.app2unit.packages.${pkgs.system}.default
            inputs.quickshell.packages.${pkgs.system}.default
            inputs.caelestia-shell.packages.${pkgs.system}.default 
            inputs.caelestia-cli.packages.${pkgs.system}.default

            # Icons
            material-symbols

            # Packages
            libnotify
            inotify-tools
            dart-sass
            wl-clipboard
            wl-clip-persist
            wl-screenrec
            ydotool
            cliphist
            bluez
            fuzzel
            slurp
            fish 
            cava 
            ddcutil 
            brightnessctl 
            networkmanager 
            lm_sensors 
            aubio
            pipewire 
            glibc
            kdePackages.qt6ct
            qt6.qtdeclarative 
            libqalculate
            grim 
            swappy
            libqalculate
            uwsm
            ibm-plex
            imagemagick
            safeeyes
            hyprpicker
            upower

            (python3.withPackages (ps: with ps; [
                aubio
                numpy
                pyaudio
                inotify
            ]))

            # Might be the wrong ones
            gdbuspp
            libpulseaudio
            rubyPackages_3_4.glib2
            gcc
        ];

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
                "eDP-1,2560x1440@165,0x0,1"
            ];

            # Default programs definitions (used in keybinds and other places)
            "$mod" = "SUPER";

            # General settings
            general = {
                "$mod" = "SUPER";           # Main modification button (passed to binds file)
                layout = "dwindle";
                gaps_in = 5;                # Windows inside gaps to make windows smaller
                gaps_out = 20;              # Window outer gaps
                border_size = 2;            # Window border thickness
                resize_on_border = true;
            };

            # Commands to execute once on Hyprland start
            exec-once = [
                # On start up enable apps on certain workspaces
                "[workspace 2 silent] vivaldi"
                "[workspace 3 silent] discord"
                "[workspace 4 silent] spotify"

                "wl-clip-persist"
                "power-profiles-daemon"
                "nm-applet --no-agent"
            ]
            ++ lib.optionals cfg.waybar.enable [
                "sh ~/.config/waybar/waybar.sh"
            ]
            ++ lib.optionals cfg.hyprpaper.enable [
                "hyprpaper"
            ];

            # Windows rules
            windowrulev2 = [
                # ...
            ];

            # Session variables passed to hyprland
            # instead of system-level environment.sessionVariables
            env = [
                "NIXOS_OZONE_WL, 1"
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
            ]
            ++ lib.optionals cfg.caelestia.enable [
                "QT_QPA_PLATFORMTHEME, qt6ct" # Caelestia shell - icon fix
            ]
            ;

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
            animations = import ./animations.nix;

            # Settings you probably don't want to change
            dwindle = {
                pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mod + P in the keybinds section below
                preserve_split = true; # You probably want this
            };

            misc = {
                force_default_wallpaper = 0; # Set to 1 to use the anime mascot wallpapers
                disable_hyprland_logo = true; # If true disables the random hyprland logo / anime girl background. :(
            };

            gestures = {
                workspace_swipe = true;
            };
        }
        // cfg.binds; # Adding dynamic bindings
    };
}