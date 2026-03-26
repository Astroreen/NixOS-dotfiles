{ pkgs, lib, ... }:
let
  # Chromium flags to enable NVIDIA hardware video acceleration
  nvidia-vaapi-flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
  ];

  vivaldi-gpu = pkgs.vivaldi.override {
    commandLineArgs = lib.concatStringsSep " " nvidia-vaapi-flags;
  };
in
{
  home = {
    packages = [
      vivaldi-gpu
      pkgs.vivaldi-ffmpeg-codecs
    ];

    sessionVariables = {
      CHROME_EXECUTABLE = "${vivaldi-gpu}/bin/vivaldi";
    };
  };
}
