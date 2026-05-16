{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Clipboard history
    cliphist
    wl-clipboard # Clipboard management fow wayland
    wl-clip-persist # Clipboard history daemon

  ];

  # Clipboard history settings
  services.cliphist = {
    enable = true;
    allowImages = true; # Allow images in clipboard history
    # Flags to put before command
    extraOptions = [
      "-max-dedupe-search"
      "10"
      "-max-items"
      "500"
    ];
  };
  services.copyq.enable = true;

  wayland.windowManager = {
    # If it is not enabled, service may not even start.
    sway.systemd.enable = true;
    # Bind for clipboard
    hyprland = {
      settings = {
        exec-once = [
          "wl-clip-persist"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        windowrule = [
          "match:class copyq, size 1100 600, center on, float on"
        ];
      };

      submaps.global.settings.bind = [
        "$mod, V, exec, copyq toggle" # Clipboard menu
      ];
    };
  };
}
