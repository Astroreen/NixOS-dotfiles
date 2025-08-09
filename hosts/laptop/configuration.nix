{ config, pkgs, ... }:

{
    imports = [
        ./hardware-configuration.nix    # Required.
      
        ../../modules/gui/nautilus      # Nautilus configuration
        ../../modules/wm/hyprland       # Window manager Hyprland
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable networking
    networking.hostName = "laptop"; # Define your hostname.
    networking.networkmanager.enable = true;

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
        ];
    };

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" "lt_LT.UTF-8/UTF-8" ];

    # Configure keymap in X11
    services.xserver.xkb = {
        layout = "us,ru,lt";
        variant = ",phonetic,us";
        options = "grp:win_space_toggle,grp:alt_shift_toggle";
    };
    services.libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
    };
    services.seatd.enable = true;

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
            powerManagement.finegrained = true;  # Requires offload below
            open = false;   # Use proprietary driver
            nvidiaSettings = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;

            prime = {
                offload.enable = true;
                intelBusId = "PCI:0:2:0";      # Use lspci to verify
                nvidiaBusId = "PCI:1:0:0";     # Use lspci to verify
            };
        };

        bluetooth = {
            enable = true;
            powerOnBoot = true;
        };
    };

    services.xserver.videoDrivers = [ "nvidia" ];
    services.blueman.enable = true;

    # Audio
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
    };

    # Display manager
    services.displayManager = {
        # CAUTION: DO NOT ENABLE BOTH!
        sddm.enable = false;
        gdm = {
            enable = true;
            wayland = true;
        };

        # Enable automatic login for the user.
        autoLogin = {
            enable = true;
            user = "astroreen";
        };

        # Defaul session to log in to. Perfect with auto login :)
        defaultSession = "hyprland";
    };

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    # Desktop Environments
    services.desktopManager.plasma6.enable = true;

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

    # List services that you want to enable:

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;
    # Security
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm-password.enableGnomeKeyring = true;
    services.gvfs.enable = true;  # Enables trash
    services.power-profiles-daemon.enable = true; # Enable power profiles

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
