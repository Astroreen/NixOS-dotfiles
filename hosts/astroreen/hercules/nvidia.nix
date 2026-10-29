# Headless NVIDIA (RTX 4080 SUPER): compute only, no display server.
{ config, ... }:
{
  # Selects the driver for hardware.nvidia; does not enable X.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable32Bit = true; # Required by virtualisation.docker.enableNvidia below

    nvidia = {
      open = true; # Ada Lovelace is supported by the open kernel modules
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = false; # GUI tool, useless headless
      nvidiaPersistenced = true; # Keep the GPU initialized between jobs (Ollama, whisper)
    };

    # CDI specs for containers: `docker run --device nvidia.com/gpu=all`.
    nvidia-container-toolkit.enable = true;
  };

  # Nextcloud AIO asks for the GPU through the legacy DeviceRequest API
  # (driver "nvidia"), which CDI alone does not serve ("could not select
  # device driver"). enableNvidia registers the nvidia runtime as default and
  # writes its config.toml; see the comment in ../pc/configuration.nix on why
  # it must not be replaced by hand. The deprecation warning is cosmetic.
  virtualisation.docker.enableNvidia = true;
}
