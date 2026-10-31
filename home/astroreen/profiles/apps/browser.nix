{ pkgs, lib, ... }:
let
  # Chromium flags to enable NVIDIA hardware video acceleration
  flags = [
    "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,AcceleratedVideoDecodeLinuxGL,WaylandLinuxDrmSyncobj,TouchpadOverscrollHistoryNavigation"
    "--ignore-gpu-blocklist"
    "--enable-gpu-rasterization"
    # Restored tabs (YouTube) stay paused until the page is clicked
    "--autoplay-policy=document-user-activation-required"
    # YouTube ships in Chromium's preloaded Media Engagement list, and a high
    # engagement score bypasses the autoplay policy above
    "--disable-features=MediaEngagementBypassAutoplayPolicies,PreloadMediaEngagementData"
  ];

  vivaldi-gpu = pkgs.vivaldi.override {
    commandLineArgs = lib.concatStringsSep " " flags;
  };

  # Chromium checks for a D-Bus notification server once, at startup. Started
  # before the shell owns org.freedesktop.Notifications, it draws its own
  # classless popup windows for the whole session instead.
  startVivaldi = pkgs.writeShellScript "start-vivaldi" ''
    for _ in {1..100}; do
      ${pkgs.systemd}/bin/busctl --user status org.freedesktop.Notifications >/dev/null 2>&1 && break
      sleep 0.1
    done
    exec ${vivaldi-gpu}/bin/vivaldi
  '';
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
          (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"[workspace 2 silent] ${startVivaldi}\")\nend")
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
