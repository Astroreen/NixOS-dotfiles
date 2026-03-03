{
  pkgs,
  osConfig,
  inputs,
  ...
}:
{

  imports = [
    # Style
    ../../modules/style/cursor/breeze # Breeze cursor style
    ../../modules/style/theme/dark/adwaita # Adwaita dark theme

    # Apps
    ../../common-apps.nix

    # Windows manager (wm)
    ../../modules/wm/hyprland # Hyprland window manager
    ../../modules/wm/hyprland/caelestia # Caelestia shell
    inputs.caelestia-shell.homeManagerModules.default # Caelestia shell module
  ];

  # Wayland, X, etc. support for session vars
  systemd.user.sessionVariables = osConfig.home-manager.users.astroreen.home.sessionVariables;

  # Hyprland settings
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix;

  programs.caelestia.systemd.environment = [
    "QT_QPA_PLATFORM=wayland;xcb"
    "XDG_SESSION_TYPE=wayland;xcb"
    "XDG_CURRENT_DESKTOP=Hyprland"
    "XDG_SESSION_DESKTOP=Hyprland"
    "QT_QPA_PLATFORMTHEME=qt6ct"
    "XDG_RUNTIME_DIR=/run/user/1000"
    "WAYLAND_DISPLAY=wayland-1"
    "QUICKSHELL_ENABLE_PORTAL=1"
  ];

  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };
}
