{ lib, ... }:
{
  imports = [
    ../common/desktop # Graphical workstation layer

    # ../../modules/tui/ollama.nix
    ../../modules/terminal/ai/lmstudio.nix

    ../profiles/apps/arduino.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix { inherit lib; };

  custom = {
    dux = {
      enable = true;
      overrideSettings = false;
      settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/dux-settings.json));
    };

    caelestia = {
      enable = false;
      settings = lib.mkDefault (
        builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json)
      );

      # Server renders via NVIDIA only: gpu-screen-recorder encodes with NVENC + CUDA.
      # If GPU encoder init fails (e.g. VRAM pressure from Ollama/faster-whisper/Docker),
      # fall back to CPU encoding so recording still works.
      recordExtraArgs = [
        "-fallback-cpu-encoding"
        "yes"
      ];
    };
  };
}
