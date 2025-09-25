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
        settings = lib.mkOption {
            type = lib.types.attrs;
            default = import ./binds.nix;
            example = "hyprland.settings = import /absolute/path/to/settings.nix or ./relative/path/to/settings.nix";
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

        # Clipboard history settings
        services.cliphist = {
            enable = true;
            allowImages = true; # Allow images in clipboard history
            # Flags to put before command
            extraOptions = [
                "-max-dedupe-search"
                "10"
                "-max-items"
                "500"
            ];
        };

        # Create systemd service to run Caelestia shell
        systemd.user.enable = true;
        systemd.user.services = {
            caelestia = lib.mkIf cfg.caelestia.enable {
                Unit = {
                    Description = "Caelestia desktop shell";
                    After = [ "hyprland-session.target" ];
                    Requires = [ "xdg-desktop-portal.service" ];
                };
                Service = {
                    Type = "exec";
                    ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
                    ExecStart = "${inputs.app2unit.packages.${pkgs.system}.default}/bin/app2unit caelestia shell";
                    Restart = "on-failure";
                    Slice = "app-graphical.slice";
                    RestartSec = "5s";
                    RestartPreventExitStatus = "0";
                    RuntimeDirectory = "caelestia";
                    RuntimeDirectoryMode = "0755";
                    # Set environment variables for the service
                    Environment = [
                        "QT_QPA_PLATFORM=wayland"
                        "XDG_SESSION_TYPE=wayland;xcb"
                        "XDG_CURRENT_DESKTOP=Hyprland"
                        "XDG_SESSION_DESKTOP=Hyprland"
                        "QT_QPA_PLATFORMTHEME=qt6ct"
                        "XDG_RUNTIME_DIR=/run/user/1000"
                        "WAYLAND_DISPLAY=wayland-1"
                        "QUICKSHELL_ENABLE_PORTAL=1"
                    ];
                };
                # Starting this in exec-once
                #Install = {
                #    WantedBy = [ "default.target" ];
                #};
            };

            # Fix for Hyprland's xdg-desktop-portal
            xdg-desktop-portal-hyprland = {
                Service = {
                    Environment = [
                        "WAYLAND_DISPLAY=wayland-1"
                        "XDG_CURRENT_DESKTOP=Hyprland"
                        "XDG_SESSION_TYPE=wayland"
                    ];
                    ExecStart = [
                        ""
                        "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland"
                    ];
                    Restart = "on-failure";
                    RestartSec = "3s";
                };

                Unit = {
                    ConditionEnvironment = ""; # clear previous Condition
                    After = [ "hyprland-session.target" ];
                };
            };
        };

        home.packages = with pkgs; [
            hyprpicker              # Color picker for Hyprland
            grim                    # Screenshot tool for wayland
            uwsm                    # Window manager for wayland
            pipewire                # PipeWire media server
            lm_sensors              # Hardware sensors
            inotify-tools           # Inotify tools
        ]
        ++ lib.optionals cfg.caelestia.enable [
            # Default packages from Caelestia
            inputs.app2unit.packages.${pkgs.system}.default
            inputs.caelestia-shell.packages.${pkgs.system}.default 
            inputs.caelestia-cli.packages.${pkgs.system}.default

            # Icons
            papirus-icon-theme
            material-symbols

            # Packages
            dart-sass               # Sass compiler
            ydotool                 # Wayland input automation tool
            fuzzel                  # Fuzzy launcher
            slurp                   # Select a region on the screen
            fish                    # Fish shell
            cava                    # Audio visualizer
            aubio                   # Audio analysis library
            glibc                   # GNU C Library
            glib                    # C library for data structures and utilities
            kdePackages.qt6ct       # Qt6 configuration tool
            qt6.qtdeclarative       # Qt6 declarative module
            libqalculate            # Calculator library
            swappy                  # Image editor for screenshots
            ibm-plex                # IBM Plex font
            imagemagick             # Image manipulation tool
            safeeyes                # Eye protection tool
            gpu-screen-recorder     # Screen recorder that uses GPU for encoding

            # Python packages
            (python3.withPackages (ps: with ps; [
                aubio
                numpy
                pyaudio
                inotify
            ]))

            # Might be the wrong packages
            gdbuspp
            libpulseaudio
            rubyPackages_3_4.glib2
            gcc
        ];

        # Wayland settings
        wayland.windowManager.hyprland = {
            enable = true;
            systemd.enable = true;
            systemd.variables = [ "--all" ];
        };

        # Hyprland settings
        wayland.windowManager.hyprland.settings = let
            # Base settings from the module
            baseSettings = {
                # Monitors
                monitor = [
                    ", preferred, auto, 1"      # Fallback option
                ];

                # Default programs definitions
                "$mod" = "SUPER";

                # General settings
                general = {
                    "$mod" = "SUPER";
                    layout = "dwindle";
                    gaps_in = 5;
                    gaps_out = 20;
                    border_size = 2;
                    resize_on_border = true;
                };

                # Base exec-once commands
                exec-once = [
                    "wl-clip-persist"
                    "wl-paste --type text --watch cliphist store"
                    "wl-paste --type image --watch cliphist store"
                    "power-profiles-daemon"
                    "nm-applet --no-agent"
                ]
                ++ lib.optionals cfg.waybar.enable [
                    "sh ~/.config/waybar/waybar.sh"
                ]
                ++ lib.optionals cfg.hyprpaper.enable [
                    "hyprpaper"
                ]
                ++ lib.optionals cfg.caelestia.enable [
                    "systemctl --user start caelestia.service"
                ];

                # Base env vars
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
                    "WAYLAND_DISPLAY, wayland-1"
                ]
                ++ lib.optionals cfg.caelestia.enable [
                    "QT_QPA_PLATFORMTHEME, qt6ct"
                    "QUICKSHELL_ENABLE_PORTAL, 1"
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

                animations = import ./animations.nix;

                dwindle = {
                    pseudotile = true;
                    preserve_split = true;
                };

                misc = {
                    force_default_wallpaper = 0;
                    disable_hyprland_logo = true;
                    session_lock_xray = true;
                };

                # Causes errors in the newer versions
                # gestures = {
                #     workspace_swipe = true;
                # };
            };

            # Custom merge function for lists
            mergeSettings = base: custom: 
                lib.recursiveUpdate base (custom // {
                # Special handling for lists that should be concatenated
                exec-once = (base.exec-once or []) ++ (custom.exec-once or []);
                env = (base.env or []) ++ (custom.env or []);
                monitor = (base.monitor or []) ++ (custom.monitor or []);
                workspace = (base.workspace or []) ++ (custom.workspace or []);
                windowrulev2 = (base.windowrulev2 or []) ++ (custom.windowrulev2 or []);
                # Add other list attributes as needed
            });
        in mergeSettings baseSettings cfg.settings;
    };
}
