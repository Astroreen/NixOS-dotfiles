{ pkgs, lib, ... }:
let
  # Chromium/Electron flags to enable NVIDIA hardware video acceleration
  nvidia-vaapi-flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
  ];

  vesktop-gpu = pkgs.vesktop.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/vesktop \
        ${lib.concatStringsSep " \\\n      " (
          map (f: "--add-flags ${lib.escapeShellArg f}") nvidia-vaapi-flags
        )}
    '';
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  });
in
{
  programs.vesktop = {
    enable = true;
    package = vesktop-gpu;
  };
}
