{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "neohtop-fixed" ''
      # GDK_BACKEND=x11 (forced) was removed: it hard-requires XWayland to
      # provide a DISPLAY, but XWayland is never lazily started in this
      # session (confirmed: zero "xwayland" mentions in hyprland.log, no
      # Xwayland process running) - this was silently working before if/when
      # XWayland happened to be running for some other reason, but fails
      # outright ("Gtk-WARNING: cannot open display: :0") once it isn't.
      # NeoHtop is GTK4, which supports native Wayland well; falling back to
      # the system default GDK_BACKEND ("wayland,x11" from
      # hosts/modules/wm/hyprland/default.nix sessionVariables) lets it try
      # native Wayland first instead of hard-requiring X11.
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      exec ${pkgs.neohtop}/bin/NeoHtop "$@"
    '')
  ];

  # This is the missing piece for the "Application" menu
  xdg.desktopEntries = {
    neohtop = {
      name = "NeoHtop";
      genericName = "System Monitor";
      exec = "neohtop-fixed";
      terminal = false;
      categories = [
        "System"
        "Monitor"
      ];
      icon = "htop"; # Or the specific icon name if you have one
      comment = "NeoHtop with Hyprland fixes";
    };
  };

  home.shellAliases = {
    htop = "neohtop-fixed";
    NeoHtop = "neohtop-fixed";
  };
}
