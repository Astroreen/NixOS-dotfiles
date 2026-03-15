_: {
  # Enable IP forwarding for Tailscale exit node and subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services = {
    tailscale = {
      enable = true;
      openFirewall = true; # Automatically open necessary firewall ports for Tailscale
    };

    tailscaleAuth = {
      enable = true; # Whether to enable tailscale.nginx-auth, to authenticate users via tailscale.
    };
  };
}
