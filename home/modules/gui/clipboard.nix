_: {
  imports = [
    ../wm/hyprland/settings/binds.nix
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

  # If it is not enabled, service may not even start.
  wayland.windowManager.sway.systemd.enable = true;

  custom.binds.global.bind = [
    "$mod, V, exec, copyq toggle" # Clipboard menu
  ];
}
