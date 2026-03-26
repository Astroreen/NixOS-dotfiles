{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix # Required.

    ../common-settings.nix # Common settings for all hosts
    ../common-services.nix # Services configuration
    ../common-apps.nix # Common applications
    ../certificates.nix # Import certificates

    ../nix-ld.nix # Some libraries to run runtime projects
    ../modules/style/theme/dark/adwaita # Adwaita dark theme
    ../modules/wm/hyprland # Window manager Hyprland
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot"; # We will align this with output of `lsblk` command
    };
    # systemd-boot.enable = true;
    grub =
      let
        grub-theme-pkg = pkgs.sleek-grub-theme.override {
          withStyle = "dark";
          withBanner = "AstroGrub Bootloader";
        };
      in
      {
        enable = true;
        efiSupport = true;
        devices = [ "nodev" ];
        useOSProber = false;
        efiInstallAsRemovable = false;
        theme = "${grub-theme-pkg}";
      };

    timeout = 3; # seconds
  };

  # Enable networking
  networking = {
    hostName = "laptop"; # Define your hostname.
    networkmanager.enable = true;

    firewall = {
      allowedTCPPorts = [
        53317 # Localsend port
        4096 # OpenCode server port
      ];

      allowedUDPPorts = [
        53317 # Localsend port
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
  };

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

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia"; # VAAPI → NVIDIA
    VDPAU_DRIVER = "nvidia"; # VDPAU → NVIDIA
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # OpenGL → NVIDIA
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json"; # Vulkan → NVIDIA
    GBM_BACKEND = "nvidia-drm"; # Wayland GBM → NVIDIA
    NVD_BACKEND = "direct"; # nvidia-vaapi-driver: direct mode
  };

  # Docker settings
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    # enableNvidia = true; # Enable NVIDIA support, deprecated
    rootless = {
      enable = false;
      setSocketVariable = false;
    };
  };

  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
