{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix # Replaced by `bootstrap server <target>` on first install
    ./disko.nix # Declarative disk layout for nixos-anywhere

    ../common/base # Headless settings shared by all hosts

    ../profiles/server/hardening.nix # Key-only SSH, passwordless sudo for wheel
    ../profiles/server/agent.nix # Unprivileged `agent` account
    ../profiles/server/containers.nix # Docker for services, rootless podman for agents
    ../profiles/server/backup.nix # Daily restic snapshots with retention
    ../profiles/server/monitoring.nix # Uptime Kuma
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10; # Keep /boot from filling up
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "server";

    # Nothing is exposed to the LAN/WAN: every service is reachable only
    # over the tailnet.
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  # First boot joins the tailnet on its own when `bootstrap` was given an
  # auth key file (copied to this path). Once logged in the key is no longer
  # read, so it can be deleted. Disable key expiry for this machine in the
  # Tailscale admin console, or SSH access dies with it.
  services.tailscale.authKeyFile = "/var/lib/tailscale/authkey";

  users.users = {
    astroreen.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
    agent.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  };

  # Home Manager for the agent account is applied together with the system,
  # so agents get the same opencode/claude-code setup without a second deploy.
  home-manager.users.agent = import ../../../home/astroreen/server/agent.nix;

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
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Set once at first install; never change it.
  system.stateVersion = "26.11"; # Did you read the comment?
}
