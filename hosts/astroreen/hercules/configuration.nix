_: {
  imports = [
    ./hardware-configuration.nix # Replaced by `bootstrap hercules <target>` on first install
    ../common/server # Server layer: disko, GRUB, hardening, agent, containers, backup

    ./nvidia.nix # RTX 4080 SUPER for GPU services
    ./github-runners.nix # Caspian ERP CI runners (moved from aktkc)
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

  # nofail mounts are not ordered before local-fs.target, so without this
  # Docker (and the Nextcloud container's bind mount) can come up before the
  # USB disk and see the empty mount point. `wants`, not `requires`: Docker
  # still starts when the disk is missing. A disk plugged in later is not
  # mounted automatically: `systemctl start mnt-nextcloud_storage.mount`,
  # then restart nextcloud-aio-nextcloud. The empty mount point itself is
  # `chattr +i`, so nothing can be written there while the disk is absent.
  systemd.services.docker = {
    wants = [ "mnt-nextcloud_storage.mount" ];
    after = [ "mnt-nextcloud_storage.mount" ];
  };

  # Bare-metal home server (Gigabyte Z790 AORUS ELITE X, i7-14700KF).
  # NixOS takes the whole NVMe; the SATA Samsung 860 EVO
  # (ata-Samsung_SSD_860_EVO_1TB_S3Z9NB0M620230V) is not managed by disko.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNU0WC13675Z";

  networking.hostName = "hercules";

  # CI and the builder agents are capped below (28G together); the rest of
  # the overflow goes to zram (zstd, ~3-4x). The zram device size is a cap on
  # uncompressed data, not reserved memory.
  zramSwap.memoryPercent = 100;
  boot.kernel.sysctl."vm.swappiness" = 150; # Swap to zram is cheap: prefer it to dropping page cache

  # When CI and the builder agents peak together, the services (sshd, Pi-hole
  # DNS for the LAN and exit-node clients, tailscaled, Docker services: ~2 GB
  # at rest) are reclaimed last (system MemoryLow below).
  #
  # Hard ceiling of the work load, so the host never runs at 100% and Pi-hole
  # keeps answering the LAN (load 270 on 28 threads took the LAN down,
  # 2026-10-31). The builder agents (T3, user.slice) and CI (caspian.slice)
  # share CPUs 0-22: 23 of 28 threads, ~82%. E-cores 23-27 stay for the
  # services in system.slice. The cpuset is shared, so either side may take
  # all 23 threads while the other is idle. Memory: work gets at most
  # 15G + 15G of the 31 GB (zram takes the overlap); over MemoryHigh it is
  # throttled, over MemoryMax the OOM killer picks inside that slice, never a
  # service. user.slice keeps 3G between High and Max: a kill there can take
  # out the T3 server or an agent mid-work, so the brake comes first.
  systemd.slices = {
    system.sliceConfig.MemoryLow = "3G";
    user.sliceConfig = {
      AllowedCPUs = "0-22";
      MemoryHigh = "12G";
      MemoryMax = "15G";
    };
    caspian.sliceConfig = {
      AllowedCPUs = "0-22";
      MemoryHigh = "14G";
      MemoryMax = "15G";
    };
  };

  # Services are reached through the tunnel and the tailnet; from the LAN only
  # Pi-hole's DNS is open (see custom.services.lan).
  custom.services.lan.interfaces = [ "enp4s0" ];

  # Tailscale exit node (approve it once in the admin console). Clients using
  # it hand their DNS to this host, which resolves with its own resolv.conf:
  # Pi-hole first, the router only if Pi-hole is down.
  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };
  networking.nameservers = [
    "127.0.0.1" # Pi-hole (published port 53)
    "192.168.50.1"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Set once at first install; never change it.
  system.stateVersion = "26.11"; # Did you read the comment?
}
