{ lib, ... }:
{
  imports = [
    ../common/home.nix

    # ../../modules/tui/ollama.nix
    ../profiles/terminal/whisper.nix
    ../../modules/terminal/ai/lmstudio.nix

    ../profiles/apps/arduino.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix { inherit lib; };

  custom.caelestia = {
    enable = true;
    enableDefaultKeyboardBinds = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));
  };
}
