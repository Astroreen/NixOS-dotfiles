_: {
  custom.services.vaultwarden = {
    enable = true;
    # Overridden anyway by data/config.json (admin page settings), which wins over env.
    domain = "https://astrovault.aktkc.lt";
    environmentFile = "/var/lib/secrets/vaultwarden.env"; # ADMIN_TOKEN=...
    environment = {
      SIGNUPS_VERIFY = "true";
      LOG_LEVEL = "warn";
    };
  };
}
