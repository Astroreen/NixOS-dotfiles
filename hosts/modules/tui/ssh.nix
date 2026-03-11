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

  # Make sshd wait for tailscale interface
  systemd.services.sshd = {
    after = [
      "tailscaled.service"
      "network-online.target"
    ];
    wants = [ "tailscaled.service" ];
  };
}
