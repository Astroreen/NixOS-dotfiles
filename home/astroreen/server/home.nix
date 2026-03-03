{
  ...
}:
{
  imports = [
    ../common/home.nix

    ../../modules/tui/ollama.nix
    ../../modules/tui/whisper.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland-settings.nix;

  programs.caelestia = {
    settings = builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json);
  };
}
