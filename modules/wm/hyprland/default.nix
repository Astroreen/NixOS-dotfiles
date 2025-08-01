# System level configuration of Hyprland
# import in your /hosts/{HOSTNAME}/configuration.nix file
{ config, pkgs, inputs, lib, ... }:

{
  # System-level Hyprland configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # CRITICAL: Proper XDG portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
    ];
    configPackages = [ inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland ];
  };

  # Enable polkit for proper permissions
  security.polkit.enable = true;

  # CRITICAL: Graphics and hardware support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Essential services for Wayland
  services.dbus.enable = true;
  services.udev.enable = true;

  # Additional environment variables for Hyprland
  environment.sessionVariables = {
    # Force Wayland for Qt apps
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # XDG variables
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";

    # Cursor
    XCURSOR_SIZE = "24";

    # Electron apps
    NIXOS_OZONE_WL = "1";

    # CRITICAL: Ensure proper backend selection
    WLR_NO_HARDWARE_CURSORS = "1";  # Sometimes needed for certain hardware
  };
}
