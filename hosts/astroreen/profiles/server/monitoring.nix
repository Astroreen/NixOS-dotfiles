_: {
  # Uptime checks and status page, web UI on :3001 (tailnet only).
  services.uptime-kuma = {
    enable = true;
    settings.HOST = "0.0.0.0";
  };
}
