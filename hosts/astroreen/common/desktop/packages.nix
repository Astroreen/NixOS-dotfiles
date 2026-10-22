{ pkgs, ... }:
{
  # Desktop-only system packages (CLI essentials live in ../base/generic.nix)
  environment.systemPackages = with pkgs; [
    # Essential packages
    bluez # Bluetooth management
    ddcutil # Monitor brightness control
    brightnessctl # Monitor brightness control
    upower # Power management daemon
    libnotify # Notifications
    pavucontrol # Sound control

    # Libraries
    openal # OpenAL library
    gtk3 # Multi-platform toolkit for graphical interfaces
    gtk4
    glib # C library - building blocks
  ];
}
