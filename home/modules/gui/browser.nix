{ pkgs, lib, ... }:
let
  # Chromium flags to enable NVIDIA hardware video acceleration
  flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj,TouchpadOverscrollHistoryNavigation"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
  ];

  vivaldi-gpu = pkgs.vivaldi.override {
    commandLineArgs = lib.concatStringsSep " " flags;
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

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "[workspace 2 silent] vivaldi"
    ];

    windowrule = [
      "match:class ^(vivaldi-stable)$, fullscreen off, workspace 2 silent"
    ];
  };
}
