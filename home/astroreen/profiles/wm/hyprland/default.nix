{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./portal.nix # xdg-desktop-portal-hyprland service fix + GTK portal dialogs
    ./binds.nix # Compositor-dispatcher keybinds (custom.keybinds)
  ];

  systemd.user.enable = true;

  home.packages = with pkgs; [
    hyprpicker # Color picker for Hyprland
    grim # Screenshot tool for wayland
    uwsm # Window manager for wayland
    lm_sensors # Hardware sensors
    inotify-tools # Inotify tools
  ];

  # Wayland settings
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    settings = import ./settings { inherit config lib pkgs; };
    plugins = [
      inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
    ];
  };
}
