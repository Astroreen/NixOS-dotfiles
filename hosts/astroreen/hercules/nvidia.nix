# Headless NVIDIA (RTX 4080 SUPER): compute only, no display server.
{ config, ... }:
{
  # Selects the driver for hardware.nvidia; does not enable X.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    nvidia = {
      open = true; # Ada Lovelace is supported by the open kernel modules
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = false; # GUI tool, useless headless
      nvidiaPersistenced = true; # Keep the GPU initialized between jobs (Ollama, whisper)
    };

    # CDI specs for containers: `docker run --device nvidia.com/gpu=all`.
    nvidia-container-toolkit.enable = true;
  };
}
