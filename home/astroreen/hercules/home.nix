_: {
  imports = [
    ../common/server # Headless server home shared by all server hosts

    ./astro-dashboard.nix # FastAPI dashboard from ~/astro (moved from aktkc)
    ../../modules/terminal/dictation # Only its transcription server, see below
  ];

  # faster-whisper server on the RTX 4080 SUPER for the desktops' dictation in
  # `remote` mode and the Astro dashboard. 0.0.0.0: the host firewall keeps it
  # tailnet-only.
  #
  # Model: stock large-v3 (the module default, Systran/faster-whisper-large-v3).
  # The Russian fine-tune bzikst/faster-whisper-large-v3-russian had a lower WER
  # on paper but kept appending fluent text that was never said, even with the
  # server's anti-hallucination settings; turbo was clearly worse on Russian.
  custom.dictation = {
    server.enable = true;
    host = "0.0.0.0";
    # Give the ~3.6 GB of VRAM back to other GPU services between dictations.
    server.idleUnloadMinutes = 10;
  };
}
