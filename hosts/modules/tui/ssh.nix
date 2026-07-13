_: {
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = true; # Whether to allow password authentication, set to false if you only want to use key-based auth
      PermitRootLogin = "no"; # Disable root login for security

      # Allows SSH to authenticate users through the system's standard login mechanism
      UsePAM = true;
    };

    openFirewall = false; # Don't open the default SSH port in the firewall, we have own settings.
    ports = [ 22 ];
  };

  networking.firewall = {
    # Don't open port 22 globally
    # Instead, allow it only on the tailscale interface
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };

  # sshd waits for network, but NOT specifically for tailscale - a tailscale
  # outage (expired auth, network flap, broken update) must never block
  # SSH/console recovery access on a headless/WoL host. The firewall rule
  # above applies dynamically once tailscale0 appears, so no startup
  # ordering against tailscaled is needed for that either.
  systemd.services.sshd = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
