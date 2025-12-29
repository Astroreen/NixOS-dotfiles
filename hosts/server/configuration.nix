{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix # Required.

    ./services.nix # Services configuration
    ../certificates.nix # Import certificates

    ../../import/common-system-apps.nix # Common system applications
    ../../modules/style/theme/dark/adwaita/adwaita-dark-system.nix # Adwaita dark theme
    ../../modules/wm/hyprland/hyprland-system.nix # Window manager Hyprland
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    # systemd-boot.enable = true;
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      theme = "${pkgs.sleek-grub-theme}";
      useOSProber = true;
    };
  };

  # Enable networking
  networking = {
    hostName = "server"; # Define your hostname.
    networkmanager.enable = true;
    interfaces.enp5s0.wakeOnLan = {
      enable = true;
      policy = [
        "magic"
        "broadcast"
      ];
    };

    firewall = {
      allowedTCPPorts = [
        22 # SSH
        8573 # Pi-hole web interface
        53317 # Localsend port
        11434 # Ollama API port
        7777 # Whisper.cpp server port
        27124 # Obsidian API server port
        9167 # KitchenOwl port

        25565 # Minecraft server port
      ];

      allowedUDPPorts = [
        53 # DNS queries
        53317 # Localsend port
        7777 # Whisper.cpp server port
        9 # Wake-on-LAN
      ];

      # Open TCP ports
      allowedTCPPortRanges = [
        # for KDE Connect
        {
          from = 1714;
          to = 1764;
        }
      ];

      # Open UDP ports
      allowedUDPPortRanges = [
        # for KDE Connect
        {
          from = 1714;
          to = 1764;
        }
      ];

      # Allow all traffic on docker interfaces
      trustedInterfaces = [ "docker0" ];
    };
  };

  # Enable SSH server
  services.openssh = {
    enable = true;

    settings = {
      # Use key-based auth only
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };

    # Change default port
    ports = [ 22 ];

    # Restrict to specific IPs
    # listenAddresses = [
    #   { addr = "0.0.0.0"; port = 22; }
    # ];
  };

  # Enable Wake-on-LAN at boot via systemd service
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
      "wireshark"
      "dialout"
      "kvm"
      "libvirtd"
    ];

    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILc4D5faB+mNx6yN2Wzzp3UTNDvKqu1/NB72/wlsrS7a u0_a345@localhost"
    ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [
      "root"
      "astroreen"
    ];
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" ]; # No more lithuanian locale "lt_LT.UTF-8/UTF-8"...

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
      enable32Bit = true; # Enable 32-bit graphics support
      extraPackages = with pkgs; [
        # Intel VAAPI drivers
        intel-media-driver # For newer Intel GPUs (Broadwell+)
        intel-vaapi-driver # For older Intel GPUs
        libva-vdpau-driver # VDPAU backend for VAAPI
        libvdpau-va-gl # VDPAU driver with OpenGL/VAAPI backend

        # NVIDIA VAAPI (if you want to use NVIDIA for encoding)
        nvidia-vaapi-driver
      ];
    };

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true; # Requires offload below
      open = false; # Use proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaPersistenced = false;

      prime = {
        offload.enable = true;
        intelBusId = "PCI:0:2:0"; # Use lspci to verify
        nvidiaBusId = "PCI:1:0:0"; # Use lspci to verify
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
    kitty # Console
    cliphist # Clipboard history
    wl-clipboard # Clipboard management fow wayland
    wl-clip-persist # Clipboard history daemon
    bluez # Bluetooth management
    ddcutil # Monitor brightness control
    brightnessctl # Monitor brightness control
    networkmanager # Network management
    wl-screenrec # Screen recording for wayland
    upower # Power management daemon
    libnotify # Notifications
    networkmanagerapplet # Network Manager applet
    pavucontrol # Sound control

    # Development tools
    vim # Vim text editor

    # System utilities
    playerctl # Music player control
    tree # `tree` command
    pciutils # `lspci` command
    libva-utils # VAAPI utilities
    ffmpeg-full # FFmpeg with VAAPI support
    ethtool # Ethernet tool
    iproute2 # Networking tools
    gnugrep # GNU grep
    gawk # GNU Awk
    coreutils # GNU Core Utilities
    openal # OpenAL library
    mesa # Mesa 3D Graphics Library
    mesa-demos # Mesa demo programs
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Use Intel Media Driver
    LD_LIBRARY_PATH = lib.mkForce "/run/opengl-driver/lib:${pkgs.openal}/lib:${pkgs.pulseaudio}/lib:${pkgs.pipewire}/lib";
  };

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  # Docker settings
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    enableNvidia = true; # Enable NVIDIA support
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
  system.stateVersion = "25.11"; # Did you read the comment?

}
