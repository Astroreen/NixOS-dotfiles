_: {
  imports = [
    ./hardware-configuration.nix # Replaced by `bootstrap aktkc <target>` on first install

    ../common/base # Headless settings shared by all hosts
    ../common/server # Server layer: disko, GRUB, hardening, agent, containers, backup

    ../profiles/server/monitoring.nix # Uptime Kuma
  ];

  # VMware VM on legacy BIOS; the virtual disk has no /dev/disk/by-id entry.
  disko.devices.disk.main.device = "/dev/sda";

  networking.hostName = "aktkc";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Set once at first install; never change it.
  system.stateVersion = "26.11"; # Did you read the comment?
}
