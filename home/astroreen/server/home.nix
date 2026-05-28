{ lib, ... }:
{
  imports = [
    ../common/home.nix

    # ../../modules/tui/ollama.nix
    ../../modules/tui/whisper.nix
    ../../modules/tui/ai/lmstudio.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland-settings.nix;

  custom.caelestia = {
    enable = true;
    enableDefaultKeyboardBinds = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));
  };
}
