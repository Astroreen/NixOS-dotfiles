{ pkgs, ... }: {

  programs.nm-applet.enable = true; # Enable Network Manager applet

  # Configuring the same ports
  networking = {
    networkmanager.enable = true;

    firewall = {
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
  };

  services = {
    # Enable systemd-resolved for DNS resolution
    resolved = {
      enable = true;
      # Disable systemd-resolved DNS stub listener to free port 53 for Pi-hole
      settings.Resolve = {
        DNSStubListener = "no";
      };
      fallbackDns = [
        "192.168.50.1"
        "8.8.8.8"
      ];
    };
  };

  # Network tools
  environment.systemPackages = with pkgs; [
    ethtool # Ethernet tool
    iproute2 # Networking tools
    dnsutils # DNS utilities
    wget # HTTP downloader
    nmap # Network scanner
    mtr # Traceroute + ping combined
    tcpdump # Packet capture
    socat # Network relay / swiss-army knife
    inetutils # telnet
  ];
}
