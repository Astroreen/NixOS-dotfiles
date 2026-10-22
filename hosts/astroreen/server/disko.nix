{ lib, ... }:
{
  # Partitioning applied by nixos-anywhere on first install (wipes the disk).
  # Point `device` at the real disk first: `lsblk -o NAME,SIZE,MODEL` on the
  # target, preferably as a stable /dev/disk/by-id/... path.
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
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
