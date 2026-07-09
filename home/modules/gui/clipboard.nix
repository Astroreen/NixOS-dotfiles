{ pkgs, lib, ... }:
let
  # hl.exec_once does not exist in the real Lua API; official pattern is
  # hl.on("hyprland.start", function() hl.exec_cmd(cmd) end).
  mkStartup = cmd: {
    _args = [
      "hyprland.start"
      (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"${cmd}\")\nend")
    ];
  };
in
{
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
        on = map mkStartup [
          "wl-clip-persist"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
        ];

        window_rule = [
          {
            match.class = "copyq";
            size = "1100 600";
            center = true;
            float = true;
          }
        ];

        bind = [
          {
            _args = [
              "SUPER + V"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"copyq toggle\")")
            ];
          } # Clipboard menu
        ];
      };
    };
  };
}
