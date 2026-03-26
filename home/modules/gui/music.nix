{ pkgs, lib, ... }:
let
  # Chromium/Electron flags to enable NVIDIA hardware video acceleration
  nvidia-vaapi-flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
  ];

  # Wrap an Electron app with NVIDIA VAAPI flags via symlinkJoin
  withGpuAccel =
    name: pkg:
    pkgs.symlinkJoin {
      inherit name;
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/${name} \
          ${lib.concatStringsSep " \\\n      " (
            map (f: "--add-flags ${lib.escapeShellArg f}") nvidia-vaapi-flags
          )}
      '';
    };
in
{
  home.packages = [
    pkgs.spotify
    (withGpuAccel "pear-desktop" pkgs.pear-desktop)
  ];
}
