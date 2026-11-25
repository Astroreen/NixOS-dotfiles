{ pkgs, ... }:
{
  # Stock pkgs.neohtop ships its own NeoHtop binary, NeoHtop.desktop and icons.
  # Previous WEBKIT_DISABLE_DMABUF_RENDERER / WEBKIT_DISABLE_COMPOSITING_MODE
  # workarounds broke WebKitGTK 2.54 redraws under Wayland (transparent window
  # with only dirty rectangles repainted); stock NeoHtop renders cleanly now.
  home.packages = [ pkgs.neohtop ];

  home.shellAliases = {
    htop = "NeoHtop";
  };
}
