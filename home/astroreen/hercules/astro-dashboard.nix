{ pkgs, lib, ... }:
let
  # Astro dashboard (FastAPI, ~/astro/main.py): status pages, transcription and
  # diary helpers. The app code is not in this repo; only its runtime is.
  # Transcription uses the faster-whisper HTTP API on pc (over the tailnet);
  # diary entries are written straight into Nextcloud AIO on this host.
  astroPython = pkgs.python3.withPackages (
    ps: with ps; [
      fastapi
      uvicorn
      jinja2
      python-multipart
      psutil
      aiofiles
      httpx
      aiohttp
    ]
  );
in
{
  # Listens on 0.0.0.0:8889; the firewall keeps it tailnet-only.
  systemd.user.services.astro-dashboard = {
    Unit = {
      Description = "Astro Dashboard";
      After = [ "network-online.target" ];
    };
    Service = {
      WorkingDirectory = "%h/astro";
      ExecStart = "${astroPython}/bin/python %h/astro/main.py";
      Environment = [
        "PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              ffmpeg # Audio conversion before transcription
              docker-client # Diary entries go into the local nextcloud-aio-nextcloud container
              openssh # Status page and whisper-server restart on the transcription host (pc)
              coreutils
            ]
          )
        }"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
