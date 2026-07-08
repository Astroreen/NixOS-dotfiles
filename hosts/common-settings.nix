{ pkgs, ... }:
{
  # Set your time zone.
  time.timeZone = "Europe/Vilnius";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [
    "ru_RU.UTF-8/UTF-8"
    "lt_LT.UTF-8/UTF-8"
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    settings = {
      auto-optimise-store = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "root"
        "astroreen"
      ];
    };

    package = pkgs.lixPackageSets.stable.lix;
  };

  # System wide packages
  environment.systemPackages = with pkgs; [
    # Essential packages
    kitty # Console
    bluez # Bluetooth management
    ddcutil # Monitor brightness control
    brightnessctl # Monitor brightness control
    networkmanager # Network management
    upower # Power management daemon
    libnotify # Notifications
    networkmanagerapplet # Network Manager applet
    pavucontrol # Sound control

    # Development tools
    vim # Vim text editor

    # Libraries
    gnugrep # GNU grep
    gawk # GNU Awk
    openal # OpenAL library
    mesa # Mesa 3D Graphics Library
    mesa-demos # Mesa demo programs
    gtk3 # Multi-platform toolkit for graphical interfaces
    glib # C library - building blocks

    # System utilities
    coreutils # GNU Core Utilities
    vulkan-tools # Vulkan utilities
    playerctl # Music player control
    tree # `tree` command
    pciutils # `lspci` command
    libva-utils # VAAPI utilities
    ffmpeg-full # FFmpeg with VAAPI support
    ethtool # Ethernet tool
    iproute2 # Networking tools
    dnsutils # DNS utilities
    cudaPackages.cudatoolkit # NVIDIA CUDA toolkit
    cmake # CMake build system
    gcc14 # GNU Compiler Collection
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
