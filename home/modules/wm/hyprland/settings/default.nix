{ pkgs, lib, ... }:
with lib;
{
  # Monitors
  monitor = [
    ", preferred, auto, 1" # Fallback option
  ];

  # Default programs definitions
  "$mod" = "SUPER";

  # General settings
  general = {
    "$mod" = "SUPER";
    layout = "dwindle";
    gaps_in = 5;
    gaps_out = 20;
    border_size = 2;
    resize_on_border = true;
  };

  # Base exec-once commands
  exec-once = [
    "wl-clip-persist"
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
    "power-profiles-daemon"
    "nm-applet --no-agent"

    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user start graphical-session.target" # Start the graphical session target to ensure all services are up
  ];

  # Base env vars
  env = [
    "NIXOS_OZONE_WL, 1"
    "XDG_SESSION_DESKTOP, Hyprland"
    "XDG_CURRENT_DESKTOP, Hyprland"
    "XDG_DESKTOP_DIR, $HOME/Desktop"
    "XDG_DOWNLOAD_DIR, $HOME/Downloads"
    "XDG_TEMPLATES_DIR, $HOME/Templates"
    "XDG_PUBLICSHARE_DIR, $HOME/Public"
    "XDG_DOCUMENTS_DIR, $HOME/Documents"
    "XDG_MUSIC_DIR, $HOME/Music"
    "XDG_PICTURES_DIR, $HOME/Pictures"
    "XDG_VIDEOS_DIR, $HOME/Videos"
    "HYPRSHOT_DIR, $HOME/Pictures/Screenshots"
    "WAYLAND_DISPLAY, wayland-1"
  ];

  # Style
  decoration = {
    rounding = 15;
    active_opacity = 1.0;
    inactive_opacity = 0.99;
    shadow = {
      enabled = true;
      range = 4;
      render_power = 3;
      color = "rgba(1a1a1aee)";
    };
    blur = {
      enabled = true;
      size = 3;
      passes = 1;
      vibrancy = 0.1696;
    };
  };

  animations = mkDefault (import ./animations.nix);

  dwindle = {
    pseudotile = true;
    preserve_split = true;
  };

  misc = {
    force_default_wallpaper = 0;
    disable_hyprland_logo = true;
    session_lock_xray = true;
  };

  # Causes errors in the newer versions
  # gestures = {
  #     workspace_swipe = true;
  # };
}
