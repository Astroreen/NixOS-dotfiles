{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "neohtop-fixed" ''
      export GDK_BACKEND=x11
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
