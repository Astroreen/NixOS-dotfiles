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
      # Repo values win on every switch, so a setting synced from one host
      # (`sync-dux-config <host>`) reaches the others. Sync before switching
      # if you changed something in the dux UI, or it is reverted.
      overrideSettings = true;
      # Machine-bound keys only; the portable rest is in profiles/wm/shell/dux
      settings = lib.importJSON ./assets/dux-settings.json;
      session = lib.importJSON ./assets/dux-session.json;
      pluginSettings = lib.importJSON ./assets/dux-plugin-settings.json;
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

    dictation.mode = "remote";
  };
}
