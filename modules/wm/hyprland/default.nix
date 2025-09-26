# System level configuration of Hyprland
# import in your /hosts/{HOSTNAME}/configuration.nix file
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # System-level Hyprland configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = false;
  };

  # CRITICAL: Proper XDG portal configuration
  xdg.portal = {
    enable = true;

    # DO NOT ENABLE THIS — it's for wlroots-based compositors, not Hyprland
    wlr.enable = false;

    extraPortals = [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # Add GTK portal for fallback
    ];

    configPackages = [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
    ];

    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Wallpaper" = [ "hyprland" ];
      };
    };
  };

  # Enable polkit for proper permissions
  security.polkit.enable = true;

  # CRITICAL: Graphics and hardware support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Essential services for Wayland
  services.udev.enable = true;
  services.dbus = {
    enable = true;
    packages = [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
    wayland-utils
    polkit_gnome # Polkit authentication agent
  ];

  # Additional environment variables for Hyprland
  environment.sessionVariables = {
    # Force Wayland for Qt apps
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt6ct"; # Caelestia shell - icon fix
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
    WLR_NO_HARDWARE_CURSORS = "1"; # Sometimes needed for certain hardware
  };

  environment.variables = {
    QT_QPA_PLATFORMTHEME = "qt6ct"; # Caelestia shell - icon fix
  };
}
