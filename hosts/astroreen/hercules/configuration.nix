_: {
  imports = [
    ./hardware-configuration.nix # Replaced by `bootstrap hercules <target>` on first install
    ../common/server # Server layer: disko, GRUB, hardening, agent, containers, backup

    ./nvidia.nix # RTX 4080 SUPER for GPU services
    ../profiles/server/services # Vaultwarden, Pi-hole, n8n, Actual, Nextcloud AIO (Docker)
  ];

  # 4TB USB disk with the bulk of the Nextcloud files (External storage),
  # moved over from pc. nofail: the host still boots while it is unplugged.
  fileSystems."/mnt/nextcloud_storage" = {
    device = "/dev/disk/by-uuid/be83c981-ab7e-40fb-b0fc-836eaaf07324";
    fsType = "ext4";
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

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
