_: {

  programs.nm-applet.enable = true; # Enable Network Manager applet

  # Tailscale SSH: tailnet logins (e.g. deploys between pc and laptop) are
  # authorized by the tailnet ACL instead of authorized_keys. Not enabled on
  # servers - it intercepts port 22 on the tailnet IP, so in ACL "check" mode
  # non-interactive key-based ssh to them would start asking for browser auth.
  services.tailscale.extraSetFlags = [ "--ssh" ];

  # Configuring the same ports
  networking.firewall = {
    allowedTCPPorts = [
      53317 # Localsend port
    ];

    allowedUDPPorts = [
      53317 # Localsend port
    ];

    # Open TCP ports
    allowedTCPPortRanges = [
      # KDE Connect
      {
        from = 1714;
        to = 1764;
      }
    ];

    # Open UDP ports
    allowedUDPPortRanges = [
      # KDE Connect
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
}
