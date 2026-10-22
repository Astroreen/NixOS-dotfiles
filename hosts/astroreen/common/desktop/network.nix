_: {

  programs.nm-applet.enable = true; # Enable Network Manager applet

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
