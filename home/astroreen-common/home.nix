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
    ../../modules/gui/lutris.nix # Lutris game manager
    # Nautilus (file manager) is imported in hosts/.../configuration.nix

    # Terminal apps (tui)
    ../../modules/tui/wine.nix # Wine configuration
    ../../modules/tui/kitty.nix # Terminal
    ../../modules/tui/shell/zsh.nix # Zsh configuration
    ../../modules/tui/shell/shell.nix # Shell settings
    ../../modules/tui/git.nix # Git
    ../../modules/tui/htop.nix # Htop on steroids
    ../../modules/tui/bat.nix # Cat(1) copy with wings
    ../../modules/tui/lsd.nix # Next gen ls command
    ../../modules/tui/devenv.nix # DevEnv for project scripts
    ../../modules/tui/ranger.nix # Terminal file manager

    # Windows manager (wm)
    ../../modules/wm/hyprland/hyprland-home.nix # Hyprland window manager

    # Languages
    ../../modules/lang/java.nix
    ../../modules/lang/javascript.nix
    ../../modules/lang/flutter.nix
  ];

  # Use dark theme
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark"; # Or another dark theme you prefer
      package = pkgs.gnome-themes-extra;
    };
  };
  xdg.configFile."gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-cursor-theme-name=breeze_cursors
    gtk-cursor-theme-size=24
    gtk-theme-name=Adwaita-dark
    gtk-application-prefer-dark-theme=1
  '';

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

  home.stateVersion = "25.05";
}
