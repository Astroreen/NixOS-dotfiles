{ lib, ... }:
{
  imports = [
    ../common/home.nix

    # ../../modules/tui/ollama.nix
    ../../modules/terminal/ai/lmstudio.nix

    ../profiles/apps/arduino.nix
  ];

  # Host specific settings - properly merged
  wayland.windowManager.hyprland.settings = import ./hyprland/settings.nix { inherit lib; };

  # Expose the transcription server on the LAN/tailnet for the Astro dashboard.
  custom.dictation.host = "0.0.0.0";

  custom.caelestia = {
    enable = true;
    enableDefaultKeyboardBinds = true;
    settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ./assets/caelestia-shell-config.json));

    # Server renders via NVIDIA only: gpu-screen-recorder encodes with NVENC + CUDA.
    # If GPU encoder init fails (e.g. VRAM pressure from Ollama/faster-whisper/Docker),
    # fall back to CPU encoding so recording still works.
    recordExtraArgs = [
      "-fallback-cpu-encoding"
      "yes"
    ];
  };
}
