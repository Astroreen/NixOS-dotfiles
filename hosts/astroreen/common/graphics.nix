{pkgs, ...}: {

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # Enable 32-bit graphics support
    };
  };

  # Graphics and display packages
  environment.systemPackages = with pkgs; [
    mesa # Mesa 3D Graphics Library
    mesa-demos # Mesa demo programs
    vulkan-tools # Vulkan utilities
    libva-utils # VAAPI utilities
    cudaPackages.cudatoolkit # NVIDIA CUDA toolkit
  ];
}
