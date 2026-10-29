_: {
  custom.services.vaultwarden = {
    enable = true;
    # data/config.json (admin page settings) wins over env; keep both in sync.
    domain = "https://vault.astroreen.dev";
    environmentFile = "/var/lib/secrets/vaultwarden.env"; # ADMIN_TOKEN=...
    environment = {
      SIGNUPS_VERIFY = "true";
      LOG_LEVEL = "warn";
    };
  };
}
