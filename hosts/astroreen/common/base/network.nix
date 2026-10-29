{ pkgs, ... }: {

  networking.networkmanager.enable = true;

  services = {
    # Enable systemd-resolved for DNS resolution. Its stub listener stays on, so
    # every program (also those reading /etc/resolv.conf themselves) gets
    # Tailscale MagicDNS names; hosts running Pi-hole turn it off
    # (hosts/modules/server/services/pihole.nix).
    resolved = {
      enable = true;
      settings.Resolve = {
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
