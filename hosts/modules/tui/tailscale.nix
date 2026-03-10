_: {
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
