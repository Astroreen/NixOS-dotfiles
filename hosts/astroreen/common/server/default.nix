# Headless server layer on top of ../base: shared by every server/VPS host.
# Per-machine values (hostName, disk device, extra services, stateVersion)
# live in hosts/astroreen/<host>/configuration.nix.
{ pkgs, ... }:
{
  imports = [
    ../base # Headless base shared by every host (desktop and server)
    ./disko.nix # Declarative disk layout for nixos-anywhere

    ../../profiles/server/hardening.nix # Key-only SSH, passwordless sudo for wheel
    ../../profiles/server/agent.nix # Unprivileged `agent` account
    ../../profiles/server/containers.nix # Docker for services, rootless podman for agents
    ../../profiles/server/monitoring.nix # Uptime Kuma
    # ../../profiles/server/backup.nix # Daily restic snapshots; off until there is a backup target
  ];

  # GRUB in hybrid mode: boots legacy BIOS (via the EF02 partition, whose
  # disk disko adds to `boot.loader.grub.devices`) and UEFI (installed to
  # the removable fallback path, so no NVRAM entry is needed). Many VPS
  # providers still boot with BIOS.
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 10; # Keep /boot from filling up
    };

    # Growing the virtual disk is enough: on the next boot the root partition
    # is extended to the end of the disk and the filesystem resized.
    growPartition = true;
  };
  fileSystems."/".autoResize = true;

  networking.firewall = {
    enable = true;
    # Only SSH (key-only) is exposed outside the tailnet, as a way in when
    # Tailscale is not logged in. Every other service is tailnet-only.
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 22 ];
  };

  # First boot joins the tailnet on its own when `bootstrap` was given an
  # auth key file (copied to this path). Once logged in the key is no longer
  # read, so it can be deleted. Disable key expiry for the machine in the
  # Tailscale admin console, or tailnet access dies with it.
  services.tailscale.authKeyFile = "/var/lib/tailscale/authkey";

  users.users = {
    astroreen = {
      openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
      linger = true; # Start user services (T3 Code server) at boot, not at first login
    };
    agent.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  };

  # Always-on headless box: never sleep.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  zramSwap.enable = true;
  services = {
    fstrim.enable = true;
    journald.settings.Journal.SystemMaxUse = "1G";
  };

  # Sessions that survive disconnects (agents keep running in tmux).
  programs = {
    tmux.enable = true;
    mosh = {
      enable = true;
      openFirewall = false; # tailscale0 is already trusted
    };
  };

  environment.systemPackages = with pkgs; [
    btop # Resource monitor
    kitty.terminfo # SSH from kitty sends TERM=xterm-kitty; without its terminfo, ncurses tools fail
  ];
}
