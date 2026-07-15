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
  services = {
    cliphist = {
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

    copyq.enable = true;
  };

  # copyq's systemd --user unit doesn't inherit the session's
  # QT_QPA_PLATFORM default (environment.sessionVariables from
  # hosts/modules/wm/hyprland/default.nix, "wayland;xcb") - confirmed via
  # journalctl: copyq's Qt tries the "xcb" platform plugin, fails to
  # connect to X11 display :0 (XWayland not running, same root cause
  # class as the earlier NeoHtop GDK_BACKEND=x11 issue), then aborts
  # entirely instead of falling back, hitting systemd's restart rate limit.
  # Force wayland explicitly for this unit.
  # A plain (non-mkForce) Environment= merge produced TWO Environment=
  # lines in the generated unit (xcb from the built-in services.copyq
  # module, wayland from this file) - systemd/glibc's environment array
  # apparently doesn't dedupe them the way a later-wins assumption would
  # suggest (still crashed identically after that attempt), so force full
  # replacement of the Environment list instead of trying to append/order
  # around the existing xcb entry.
  systemd.user.services.copyq.Service.Environment = lib.mkForce "QT_QPA_PLATFORM=wayland";

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
            match.class = "com.github.hluk.copyq";
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
