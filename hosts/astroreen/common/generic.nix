{ pkgs, ... }:
{
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
    };

    package = pkgs.lixPackageSets.stable.lix;
  };

  # System wide packages
  environment.systemPackages = with pkgs; [
    # Essential packages
    bluez # Bluetooth management
    ddcutil # Monitor brightness control
    brightnessctl # Monitor brightness control
    upower # Power management daemon
    libnotify # Notifications
    pavucontrol # Sound control

    # Development tools
    vim # Vim text editor

    # Libraries
    gnugrep # GNU grep
    gawk # GNU Awk
    openal # OpenAL library
    gtk3 # Multi-platform toolkit for graphical interfaces
    gtk4
    glib # C library - building blocks

    # System utilities
    coreutils # GNU Core Utilities
    tree # `tree` command
    pciutils # `lspci` command
    cmake # CMake build system
    gcc14 # GNU Compiler Collection
  ];
}
