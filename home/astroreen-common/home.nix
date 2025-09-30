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

    # Apps (gui)
    ../../modules/gui/apps.nix # Standard apps to install
    ../../modules/gui/vscode/vscode.nix # VSCode
    ../../modules/gui/obs.nix # OBS Studio
    # Nautilus (file manager) is imported in hosts/.../configuration.nix

    # Terminal apps (tui)
    ../../modules/tui/kitty.nix # Terminal
    ../../modules/tui/shell.nix # Shell settings
    ../../modules/tui/git.nix # Git
    ../../modules/tui/htop.nix # Htop on steroids
    ../../modules/tui/bat.nix # Cat(1) copy with wings
    ../../modules/tui/lsd.nix # Next gen ls command
    ../../modules/tui/devenv.nix # DevEnv for project scripts

    # Windows manager (wm)
    ../../modules/wm/hyprland/hyprland.nix # Hyprland window manager

    # Languages
    ../../modules/lang/java.nix
    ../../modules/lang/javascript.nix
    ../../modules/lang/flutter.nix
  ];

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

  home.stateVersion = "25.05";
}
