_: {
  imports = [
    ../common/server # Headless server home shared by all server hosts

    ./astro-dashboard.nix # FastAPI dashboard from ~/astro (moved from aktkc)
    ../../modules/terminal/dictation # Only its transcription server, see below
  ];

  # faster-whisper server on the RTX 4080 SUPER for the desktops' dictation in
  # `remote` mode and the Astro dashboard. 0.0.0.0: the host firewall keeps it
  # tailnet-only.
  custom.dictation = {
    server.enable = true;
    host = "0.0.0.0";
    modelPath = "/home/astroreen/.local/share/faster-whisper-large-v3-turbo";
    modelRepo = "mobiuslabsgmbh/faster-whisper-large-v3-turbo";
  };
}
