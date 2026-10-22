{ pkgs, ... }: {

  networking.networkmanager.enable = true;

  services = {
    # Enable systemd-resolved for DNS resolution
    resolved = {
      enable = true;
      # Disable systemd-resolved DNS stub listener to free port 53 for Pi-hole
      settings.Resolve = {
        DNSStubListener = "no";
        FallbackDNS = [
          "192.168.50.1"
          "8.8.8.8"
        ];
      };
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
