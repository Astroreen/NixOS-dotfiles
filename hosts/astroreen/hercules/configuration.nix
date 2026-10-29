_: {
  imports = [
    ./hardware-configuration.nix # Replaced by `bootstrap hercules <target>` on first install
    ../common/server # Server layer: disko, GRUB, hardening, agent, containers, backup

    ./nvidia.nix # RTX 4080 SUPER for GPU services
  ];

  # Bare-metal home server (Gigabyte Z790 AORUS ELITE X, i7-14700KF).
  # NixOS takes the whole NVMe; the SATA Samsung 860 EVO
  # (ata-Samsung_SSD_860_EVO_1TB_S3Z9NB0M620230V) is not managed by disko.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNU0WC13675Z";

  networking.hostName = "hercules";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Set once at first install; never change it.
  system.stateVersion = "26.11"; # Did you read the comment?
}
