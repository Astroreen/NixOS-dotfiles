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

  # Default browser, plus PDFs in the browser instead of a dedicated viewer.
  # Declared so Vivaldi has no reason to rewrite mimeapps.list itself.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "vivaldi-stable.desktop";
      "application/xhtml+xml" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
      "application/pdf" = "vivaldi-stable.desktop";
    };
  };

  wayland.windowManager.hyprland.settings = {
    on = [
      {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"[workspace 2 silent] vivaldi\")\nend")
        ];
      }
    ];

    window_rule = [
      {
        match.class = "^(vivaldi-stable)$";
        fullscreen = false;
        workspace = "2 silent";
      }
    ];
  };
}
