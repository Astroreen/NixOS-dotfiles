{ lib, ... }:
{
  # Partitioning applied by nixos-anywhere on first install (wipes the disk).
  # Each host sets `disko.devices.disk.main.device` to its real disk:
  # `lsblk -o NAME,SIZE,MODEL` on the target, preferably as a stable
  # /dev/disk/by-id/... path.
  #
  # The layout boots on both legacy BIOS and UEFI machines (see GRUB in
  # ./default.nix): the 1M EF02 partition holds GRUB's BIOS core image,
  # the ESP holds the EFI loader and /boot.
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition, unused on UEFI
        };
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
