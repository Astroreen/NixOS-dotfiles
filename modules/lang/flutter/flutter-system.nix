{ pkgs, ... }:
{
  nixpkgs.config = {
    android_sdk.accept_license = true;
  };

  # Enable KVM for Android Emulator hardware acceleration
  virtualisation.libvirtd.enable = true;

  # Android device access:
  # android-udev-rules has been removed on NixOS; modern systems rely on
  # built-in systemd uaccess rules via logind. No extra udev package is needed.

  # Programs that need to be available system-wide
  programs.adb.enable = true; # Android Debug Bridge

  # Prefer NVIDIA Vulkan ICD for host-accelerated Android Emulator on this machine
  environment.sessionVariables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  environment.sessionVariables.__GLX_VENDOR_LIBRARY_NAME = "nvidia";
}
