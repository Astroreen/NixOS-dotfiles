_: {
  # DNS for the LAN: point the router's DNS server at this host.
  custom.services.pihole = {
    enable = true;
    environmentFile = "/var/lib/secrets/pihole.env"; # FTLCONF_webserver_api_password=...
  };
}
