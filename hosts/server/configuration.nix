{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix # Required.

    ./microphone.nix # Virtual microphone for OBS Studio

    ../common-settings.nix # Common settings for all hosts
    ../common-services.nix # Services configuration
    ../common-apps.nix # Common applications
    ../certificates.nix # Import certificates

    ../nix-ld.nix # Some libraries to run runtime projects
    ../modules/style/theme/dark/adwaita # Adwaita dark theme
    ../modules/wm/hyprland # Window manager Hyprland
  ];

  # Bootloader.
  boot = {
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "vt.global_cursor_default=0"
      "udev.log_level=3"
      "fbcon=nodefer"
      # GRUB's gfxmodeEfi request doesn't reliably survive the UEFI GOP ->
      # kernel handoff (firmware may silently negotiate a lower resolution
      # regardless of what GRUB asked for), so Plymouth was inheriting a
      # small framebuffer and rendering its animation unscaled in the
      # top-left corner instead of filling the panel. Force the initial
      # framebuffer resolution explicitly via the kernel's own video= param
      # before nvidia_drm/Plymouth take over. Connector name confirmed to
      # match Hyprland's "DP-3" 1:1 via /sys/class/drm/card1-DP-3/status.
      # NOTE: confirmed via dmesg timeline that this DID fix the early
      # simple-framebuffer stage (215x45 text grid == exactly 3440x1440 at
      # a 16x32 font), but Plymouth STILL renders small - suspected because
      # proprietary nvidia-drm KMS doesn't honor video= at all (that's an
      # fbdev/generic-DRM convention; nvidia picks its own mode from EDID)
      # and may be choosing a non-native mode on its own takeover. Keeping
      # this param since it's still correct/harmless for the pre-nvidia
      # stage; investigating the post-nvidia-drm mode separately below.
      "video=DP-3:3440x1440@165"
    ];

    loader = {
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
          useOSProber = true;
          efiInstallAsRemovable = false;
          theme = "${grub-theme-pkg}";
          # Without an explicit gfxmode, GRUB's "auto" mode picks a
          # conservative resolution (e.g. 1024x768) that doesn't match the
          # center monitor's native 3440x1440. The theme's boxes are
          # percentage-positioned, so on a smaller unscaled framebuffer they
          # render into a small canvas anchored at the display's top-left
          # corner instead of filling/centering on the full screen.
          gfxmodeEfi = "3440x1440";
          # Keep GRUB's video mode across the Linux/Plymouth handoff instead
          # of switching modes again (matches quiet/splash kernel params).
          gfxpayloadEfi = "keep";
        };

      timeout = 5; # seconds
    };

    plymouth = {
      enable = true;
      theme = "loader_2";
      # Root cause confirmed by isolation test (swapping to the stock
      # "bgrt" theme rendered correctly, proving this is theme-specific,
      # not a system-wide DRM/resolution issue) plus reading the actual
      # theme script: loader_2.script centers the question/password/message
      # sprites via `screen.half.w/h = Window.GetWidth(0)/GetHeight(0) / 2`
      # (no offset - correct), but the flyingman logo-animation sprite is
      # the ONE place in the whole script that instead does
      # `Window.GetX() + (Window.GetWidth(0)/2 - ...)`. Window.GetX()/GetY()
      # return THIS screen's absolute offset in Plymouth's own multi-head
      # layout (detected independently of Hyprland, since Plymouth runs
      # before Wayland starts) while GetWidth(0)/GetHeight(0) hard-codes
      # screen index 0's size - if DP-3 isn't screen 0 in Plymouth's own
      # enumeration order, position offset and size come from two
      # different screens, producing exactly the observed small/offset
      # render. Patch the upstream theme to drop the stray GetX()/GetY()
      # offsets, matching the same centering convention used everywhere
      # else in this same script.
      themePackages = [
        (pkgs.runCommand "adi1090x-plymouth-themes-patched" { } ''
          mkdir -p "$out"
          cp -r ${pkgs.adi1090x-plymouth-themes}/* "$out"/
          chmod -R u+w "$out"
          substituteInPlace "$out/share/plymouth/themes/loader_2/loader_2.script" \
            --replace-fail \
              'flyingman_sprite.SetX(Window.GetX() + (Window.GetWidth(0) / 2 - flyingman_image[0].GetWidth() / 2));' \
              'flyingman_sprite.SetX((Window.GetWidth(0) / 2 - flyingman_image[0].GetWidth() / 2));' \
            --replace-fail \
              'flyingman_sprite.SetY(Window.GetY() + (Window.GetHeight(0) / 2 - flyingman_image[0].GetHeight() / 2));' \
              'flyingman_sprite.SetY((Window.GetHeight(0) / 2 - flyingman_image[0].GetHeight() / 2));'
          # loader_2.plymouth's ImageDir=/ScriptFile= are ABSOLUTE paths baked
          # in at the ORIGINAL package's build time, still pointing at
          # ${pkgs.adi1090x-plymouth-themes} (the unpatched store path) even
          # after copying the tree here - NixOS's plymouth module reads these
          # fields verbatim (see nixos/modules/system/boot/plymouth.nix,
          # themesEnv buildEnv symlinks loader_2/ correctly to THIS derivation,
          # but the .plymouth file's own text still repoints Plymouth back to
          # the stale original script). Rewrite them to point at $out instead.
          for f in "$out"/share/plymouth/themes/*/*.plymouth; do
            substituteInPlace "$f" \
              --replace-quiet "${pkgs.adi1090x-plymouth-themes}" "$out"
          done
        '')
      ];
    };

    initrd = {
      systemd.enable = true;
      verbose = false;
      kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      systemd.services.plymouth-start.serviceConfig.ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 4"
      ];
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
        9167 # KitchenOwl port
        4096 # OpenCode server port
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
      "dialout"
    ];

    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };

  services = {
    logind.settings.Login = {
      LidSwitchIgnoreInhibited = "no";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    # Power management settings
    power-profiles-daemon.enable = false; # Enable power profiles
    upower.enable = false; # Enable upower for battery management
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
      modesetting.enable = true; # Wayland requires kernel mode setting (KMS) to be enabled
      powerManagement.enable = false; # Disable for Desktop stability
      powerManagement.finegrained = false; # Disable (this is for laptops, requires offload)
      open = false; # Use proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaPersistenced = true; # Set to true for Ollama/Whisper performance

      # No use for PC, only usefull on laptop
      # prime = {
      #   offload.enable = false;
      #   intelBusId = "PCI:0:2:0"; # Use lspci to verify
      #   nvidiaBusId = "PCI:1:0:0"; # Use lspci to verify
      # };
    };
    nvidia-container-toolkit.enable = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Mount configuration
  fileSystems = {
    "/mnt/nextcloud_storage" = {
      device = "/dev/disk/by-uuid/be83c981-ab7e-40fb-b0fc-836eaaf07324";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/windows" = {
      device = "/dev/disk/by-uuid/0E8696038695EC09";
      fsType = "ntfs";
      options = [
        "uid=1000"
        "gid=100"
        "rw"
        "user"
        "exec"
        "umask=003"
      ];
    };
  };

  environment.sessionVariables = {
    ELECTRON_ENABLE_FEATURES = "VaapiVideoDecoder,VaapiVideoEncoder";
    LIBVA_DRIVER_NAME = "nvidia"; # VAAPI → NVIDIA
    VDPAU_DRIVER = "nvidia"; # VDPAU → NVIDIA
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # OpenGL → NVIDIA
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"; # Vulkan → NVIDIA
    GBM_BACKEND = "nvidia-drm"; # Wayland GBM → NVIDIA
    NVD_BACKEND = "direct"; # nvidia-vaapi-driver: direct mode
  };

  # Docker settings
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    enableNvidia = true; # Enable NVIDIA support, deprecated
    rootless = {
      enable = false;
      setSocketVariable = false;
    };
  };

  powerManagement.enable = false;
  # No hibernation for the server
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
