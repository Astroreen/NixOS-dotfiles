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
  # Model: large-v3 fine-tuned on Russian (Common Voice 17; WER 6.39 vs 9.84 for
  # stock large-v3 per antony66/whisper-large-v3-russian), CTranslate2 float16.
  # Same size and speed as large-v3; turbo was faster but clearly worse on
  # Russian. Other languages may suffer; stock large-v3 would be
  # Systran/faster-whisper-large-v3.
  custom.dictation = {
    server.enable = true;
    host = "0.0.0.0";
    modelPath = "/home/astroreen/.local/share/faster-whisper-large-v3-russian";
    modelRepo = "bzikst/faster-whisper-large-v3-russian";
    # Give the ~3.6 GB of VRAM back to other GPU services between dictations.
    server.idleUnloadMinutes = 10;
  };
}
