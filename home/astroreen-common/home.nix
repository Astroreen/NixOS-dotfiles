{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}:
{
  imports = [
    # Style
    ../../modules/style/cursor/breeze # Breeze cursor style
    ../../modules/style/theme/dark/adwaita/adwaita-dark-home.nix # Adwaita dark theme

    # Apps
    ../../import/common-home-apps.nix

    # Windows manager (wm)
    ../../modules/wm/hyprland/hyprland-home.nix # Hyprland window manager
  ];

  # Wayland, X, etc. support for session vars
  systemd.user.sessionVariables = osConfig.home-manager.users.astroreen.home.sessionVariables;

  home.username = "astroreen";
  home.homeDirectory = "/home/astroreen";

  # Hyprland settings
  hyprland = {
    settings = import ./hyprland/settings.nix;

    waybar.enable = false;
    hyprpaper = {
      enable = false;
      wallpaper = ./assets/astronaut.jpg;
    };

    caelestia = {
      enable = true;
      wallpapers = ./assets/astronaut.jpg;
      avatar = ./assets/avatar.jpg;

      # All config options could be found here: https://github.com/caelestia-dots/shell/tree/main/config
      # or you could take a look at my caelestia shell.json file and tweak it to your liking.
      shell-file = ./assets/caelestia-shell-config.json;
    };
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };

  home.stateVersion = "25.11";
}
