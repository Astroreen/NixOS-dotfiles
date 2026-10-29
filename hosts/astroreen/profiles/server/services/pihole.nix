_: {
  # DNS for the LAN: point the router's DNS server at this host.
  custom.services.pihole = {
    enable = true;
    environmentFile = "/var/lib/secrets/pihole.env"; # FTLCONF_webserver_api_password=...
    # Tailnet names (hercules, pc, ...) come from Tailscale MagicDNS.
    forwardZones."tail15a705.ts.net" = "100.100.100.100";
  };
}
