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

    # Server renders via NVIDIA only: gpu-screen-recorder encodes with NVENC + CUDA.
    # If GPU encoder init fails (e.g. VRAM pressure from Ollama/Whisper/Docker),
    # fall back to CPU encoding so recording still works.
    recordExtraArgs = [
      "-fallback-cpu-encoding"
      "yes"
    ];
  };
}
