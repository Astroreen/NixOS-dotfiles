{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix # Required.
    ../common/desktop # Graphical workstation layer

    ./microphone.nix # Virtual microphone for OBS Studio

    ../profiles/style/theme/dark/adwaita # Adwaita dark theme
    ../profiles/wm/hyprland # Window manager Hyprland
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
      # Portrait side monitors (Hyprland transform 3 / 1). Plymouth rotates
      # a head only from the connector's "panel orientation" DRM property
      # (renderers/drm/plugin.c, connector_orientation_prop_to_rotation);
      # the kernel attaches it for any driver from the video= option
      # (drm_connector.c, drm_connector_get_cmdline_mode). Left Side Up ->
      # Plymouth rotates counter-clockwise, Right Side Up -> clockwise.
      "video=DP-2:panel_orientation=left_side_up"
      "video=HDMI-A-1:panel_orientation=right_side_up"
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
      # Every adi1090x theme (all 80 share one script template) centers its
      # sprites with Window.GetWidth(0)/GetHeight(0), i.e. the size of
      # Plymouth's display index 0. The script plugin
      # (src/plugins/splash/script/script-lib-sprite.c, update_displays)
      # puts all heads on ONE virtual canvas of max_width x max_height
      # (3440x1440 here) and centers each head inside it, so only the
      # canvas center maps to the center of every monitor. Display 0 is
      # the lowest DRM connector id, HDMI-A-1 (1920x1080, id 128 < DP-3's
      # 139), so the animation landed at (960,540) of the canvas: upper
      # left on DP-3 and shifted on the 1080p screens too. The argument-less
      # Window.GetWidth()/GetHeight() return the canvas size instead. (The
      # old fix dropped Window.GetX()/GetY(), but without an index those
      # return MIN(0, offsets) = 0, so it changed nothing.)
      themePackages = [
        (pkgs.runCommand "adi1090x-plymouth-themes-patched" { } ''
          mkdir -p "$out"
          cp -r ${pkgs.adi1090x-plymouth-themes}/* "$out"/
          chmod -R u+w "$out"
          for f in "$out"/share/plymouth/themes/*/*.script; do
            substituteInPlace "$f" \
              --replace-fail 'Window.GetWidth(0)' 'Window.GetWidth()' \
              --replace-fail 'Window.GetHeight(0)' 'Window.GetHeight()'
          done
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
    hostName = "pc"; # Define your hostname.
    interfaces.enp5s0.wakeOnLan = {
      enable = true;
      policy = [
        "magic"
        "broadcast"
      ];
    };

    firewall = {
      allowedTCPPorts = [
        11434 # Ollama API port
        7777 # faster-whisper server port
        25565 # Minecraft server port
      ];

      allowedUDPPorts = [
        7777 # faster-whisper server port
        9 # Wake-on-LAN
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

  # Since this is a server, we don't want to suspend or hibernate
  services = {
    logind.settings.Login = {
      LidSwitchIgnoreInhibited = "no";
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    xserver.videoDrivers = [ "nvidia" ];

    # SDDM's greeter runs in Weston (kiosk shell), which knows nothing about
    # the Hyprland monitor layout: the portrait heads came up unrotated and
    # the login form landed on the first output instead of the center one.
    # Only light the main monitor for the greeter; the session sets the rest.
    # Same weston.ini as the NixOS default otherwise (keyboard, libinput).
    displayManager.sddm.wayland.compositorCommand =
      let
        xkb = config.services.xserver.xkb;
        mouse = config.services.libinput.mouse;
        westonIni = pkgs.writeText "weston.ini" ''
          [keyboard]
          keymap_model=${xkb.model}
          keymap_layout=${xkb.layout}
          keymap_variant=${xkb.variant}
          keymap_options=${xkb.options}

          [libinput]
          enable-tap=${lib.boolToString mouse.tapping}
          left-handed=${lib.boolToString mouse.leftHanded}

          [output]
          name=HDMI-A-1
          mode=off

          [output]
          name=DP-2
          mode=off
        '';
      in
      "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";

    # Power management settings
    power-profiles-daemon.enable = false; # Enable power profiles
    upower.enable = false; # Enable upower for battery management
  };
  powerManagement.enable = false;
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Drivers for hardware
  hardware = {
    graphics.extraPackages = with pkgs; [
      libva-vdpau-driver # VDPAU backend for VAAPI
      libvdpau-va-gl # VDPAU driver with OpenGL/VAAPI backend
      nvidia-vaapi-driver # VAAPI via NVDEC (required by LIBVA_DRIVER_NAME="nvidia" / NVD_BACKEND="direct")
    ];

    nvidia = {
      modesetting.enable = true; # Wayland requires kernel mode setting (KMS) to be enabled
      powerManagement.enable = false; # Disable for Desktop stability
      powerManagement.finegrained = false; # Disable (this is for laptops, requires offload)
      open = false; # Use proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaPersistenced = true; # Set to true for Ollama/faster-whisper performance
    };

    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = true; # ensure nvidia-smi etc. are mounted into containers
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Mount configuration
  # The 4TB Nextcloud disk moved to hercules (hosts/astroreen/hercules).
  fileSystems = {
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
  # DO NOT try to "cleanly" reimplement enableNvidia manually again - tried
  # twice on 2026-07-13 and failed production twice:
  #   attempt 1: dropped enableNvidia entirely, registered nothing manually
  #     -> daemon deregistered the "nvidia" runtime name -> `docker start`
  #     failed with "unknown or invalid runtime name: nvidia" for ALL 26
  #     containers, GPU or not (enableNvidia sets default-runtime for every
  #     container, and Docker bakes the runtime name into HostConfig at
  #     creation time - can't be changed without recreating the container).
  #   attempt 2: manually replicated daemon.settings.runtimes.nvidia +
  #     default-runtime = "nvidia", but NOT the
  #     environment.etc."nvidia-container-runtime/config.toml" that
  #     virtualisation.docker.enableNvidia ALSO writes (see nixpkgs
  #     nixos/modules/services/hardware/nvidia-container-toolkit/default.nix,
  #     the `mkIf config.virtualisation.docker.enableNvidia` block). Without
  #     that config.toml's `[nvidia-container-runtime] runtimes = ["docker-runc"
  #     "runc" "crun"]`, nvidia-container-runtime can't locate the low-level
  #     runtime and errors "no runtime binary found from candidate list:
  #     [runc crun]" -> dockerd reports "could not select device driver
  #     nvidia with capabilities: [[gpu]]" -> nextcloud-aio-nextcloud (the
  #     one real GPU consumer, via legacy Docker DeviceRequest API) can't
  #     start, breaking the whole Nextcloud AIO stack.
  # enableNvidia atomically writes ALL THREE required pieces together and is
  # the only proven-correct config. The "deprecated" warning is cosmetic;
  # do not remove this option without first fully reproducing everything in
  # nixos/modules/services/hardware/nvidia-container-toolkit/default.nix's
  # `mkIf config.virtualisation.docker.enableNvidia` block by hand AND testing
  # end-to-end (incl. `docker exec nextcloud-aio-nextcloud nvidia-smi`) before
  # touching the live production server.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    enableNvidia = true; # deprecated but the only config verified to fully work - see comment above
    rootless = {
      enable = false;
      setSocketVariable = false;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
