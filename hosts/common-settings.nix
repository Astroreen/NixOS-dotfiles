{ pkgs, ... }:
{
  # Set your time zone.
  time.timeZone = "Europe/Vilnius";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" ]; # No more lithuanian locale "lt_LT.UTF-8/UTF-8"...

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
    vulkan-tools # Vulkan utilities
    gtk3 # Multi-platform toolkit for graphical interfaces
    glib # C library - building blocks
    libxxf86vm # Extension library
    libxcursor # X cursor managment library
    libxrandr # xlib extension library
    libxi
    libxinerama # Extension to x11
    libxtst # Library for the xtest and record x11 extension
    wayland
    libx11 # Core x11 protocol client library
    foo2zjs # Printer drivers
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
