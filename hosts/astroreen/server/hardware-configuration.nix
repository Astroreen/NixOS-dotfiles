# Placeholder so the flake evaluates before the machine is installed.
# `bootstrap server <target>` overwrites this file with the real
# `nixos-generate-config --no-filesystems` output (disko owns fileSystems).
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
