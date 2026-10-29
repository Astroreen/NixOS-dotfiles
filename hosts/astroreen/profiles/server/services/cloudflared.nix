_: {
  # Remotely managed tunnel; ingress rules are edited in the Cloudflare dashboard.
  custom.services.cloudflared = {
    enable = true;
    environmentFile = "/var/lib/secrets/cloudflared.env"; # TUNNEL_TOKEN=...
  };
}
