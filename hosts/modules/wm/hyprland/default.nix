{
  pkgs,
  inputs,
  ...
}:

{
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = false;
    };

    # Enable GPU screen recording (mostly for Caelestia shell, but could be useful for others)
    gpu-screen-recorder.enable = true;
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

  # Adding Hyprland's Cachix cache for faster builds and updates
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  # Essential services for Wayland
  services = {
    udev.enable = true;
    dbus = {
      enable = true;
      packages = [
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };

  # Enable polkit for proper permission manager
  security.polkit.enable = true;

  environment = {
    systemPackages = with pkgs; [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
      xdg-desktop-portal
      wayland-utils
      polkit_gnome # Polkit authentication agent
    ];

    # Additional environment variables for Hyprland
    sessionVariables = {
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

    variables = {
      QT_QPA_PLATFORMTHEME = "qt6ct"; # Caelestia shell - icon fix
    };
  };
}
