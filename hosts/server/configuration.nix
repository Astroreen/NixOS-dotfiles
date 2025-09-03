{ config, pkgs, ... }:

{
    imports = [
        ./hardware-configuration.nix    # Required.

        ./services.nix                  # Services configuration
      
        ../../modules/gui/nautilus      # Nautilus configuration
        ../../modules/wm/hyprland       # Window manager Hyprland
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable networking
    networking = {
        hostName = "server"; # Define your hostname.
        networkmanager.enable = true;
        interfaces.enp5s0.wakeOnLan = {
            enable = true;
            policy = [ "magic" "broadcast" "multicast" "unicast" ];
        };

        firewall = {
            allowedTCPPorts = [       
                8573    # Pi-hole web interface
                53317   # Localsend port
                11434   # Ollama API port
                7777    # Whisper.cpp server port
                27124   # Obsidian API server port
                9167    # KitchenOwl port

                # RustDesk - signal, relay, 
                21114   # Pro, API
                21115   # WebSocket port
                21116   # WebSocket port
                21117   #
                21118   # WebSocket port
                21119   # WebSocket port
            ];
    
            allowedUDPPorts = [ 
                53      # DNS queries
                53317   # Localsend port
                7777    # Whisper.cpp server port
                9       # Wake-on-LAN
                21116   # RustDesk
            ];
    
            # Allow all traffic on docker interfaces
            trustedInterfaces = [ "docker0" ];
        };
    };

    systemd.services.wol-enable = {
        description = "Enable Wake-on-LAN";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.ethtool}/bin/ethtool -s enp5s0 wol g";
        };
    };

    # Set your time zone.
    time.timeZone = "Europe/Vilnius";

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.astroreen = {
        isNormalUser = true;
        description = "astroreen";
        extraGroups = [ 
            "networkmanager" 
            "wheel" 
            "video"
            "render" 
            "audio" 
            "input" 
            "seat" 
            "bluetooth"
            "docker"
        ];
    };

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" "lt_LT.UTF-8/UTF-8" ];

    # Drivers for hardware
    hardware = {
        # Has been moved to graphics section below.
        #opengl = {
        #    enable = true;
        #    driSupport = true;  # Enable DRI support
        #    driSupport32Bit = true;  # Enable 32-bit DRI support
        #};

        graphics = {
            enable = true;
            enable32Bit = true;  # Enable 32-bit graphics support
            extraPackages = with pkgs; [
                # Intel VAAPI drivers
                intel-media-driver      # For newer Intel GPUs (Broadwell+)
                intel-vaapi-driver      # For older Intel GPUs
                vaapiVdpau              # VDPAU backend for VAAPI
                libvdpau-va-gl          # VDPAU driver with OpenGL/VAAPI backend
      
                # NVIDIA VAAPI (if you want to use NVIDIA for encoding)
                nvidia-vaapi-driver
            ];
        };

        nvidia = {
            modesetting.enable = true;
            powerManagement.enable = true;
            powerManagement.finegrained = true; # Requires offload below
            open = false;                       # Use proprietary driver
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
            nvidiaPersistenced = false;

            prime = {
                offload.enable = true;
                intelBusId = "PCI:0:2:0";      # Use lspci to verify
                nvidiaBusId = "PCI:1:0:0";     # Use lspci to verify
            };
        };
        nvidia-container-toolkit.enable = true;

        bluetooth = {
            enable = true;
            powerOnBoot = true;
        };
    };

    # Mount configuration
    fileSystems."/mnt/nextcloud_storage" = {
        device = "/dev/disk/by-uuid/be83c981-ab7e-40fb-b0fc-836eaaf07324";
        fsType = "ext4";
        options = [ "defaults" ];
    };

    # System wide packages
    environment.systemPackages = with pkgs; [
        # Essential packages
        kitty                   # Console
        cliphist                # Clipboard history
        wl-clipboard            # Clipboard management fow wayland
        wl-clip-persist         # Clipboard history daemon
        bluez                   # Bluetooth management
        ddcutil                 # Monitor brightness control
        brightnessctl           # Monitor brightness control
        networkmanager          # Network management
        wl-screenrec            # Screen recording for wayland
        upower                  # Power management daemon
        libnotify               # Notifications
        networkmanagerapplet    # Network Manager applet
        pavucontrol             # Sound control

        # Development tools
        vim                     # Vim text editor

        # System utilities
        playerctl               # Music player control
        tree                    # `tree` command
        pciutils                # `lspci` command
        libva-utils             # VAAPI utilities
        ffmpeg-full             # FFmpeg with VAAPI support
        ethtool                 # Ethernet tool
        iproute2                # Networking tools
        gnugrep                 # GNU grep
        gawk                    # GNU Awk
        coreutils               # GNU Core Utilities

        # Themes
        adwaita-icon-theme      # Adwaita icon theme
        adwaita-qt              # Adwaita Qt theme
        adwaita-qt6             # Adwaita Qt6 theme
        gnome-themes-extra      # Extra GNOME themes
    ];

    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";  # Use Intel Media Driver
        
        # Dark theme
        GTK_THEME = "Adwaita:dark";
        QT_STYLE_OVERRIDE = "adwaita-dark";
    };
  
    # Fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono                                                                     
        font-awesome
    ];

    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        enableNvidia = true;  # Enable NVIDIA support
        rootless = {
            enable = false;
            setSocketVariable = false;
        };
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "25.05"; # Did you read the comment?

}
