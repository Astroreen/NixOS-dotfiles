{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kdePackages.breeze # Breeze cursor package
  ];

  # Add cursor configuration
  home.pointerCursor = {
    name = "breeze_cursors";
    package = pkgs.kdePackages.breeze;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  home.sessionVariables.XCURSOR_THEME = "breeze_cursors"; # Cursor theme
  home.sessionVariables.XCURSOR_SIZE = "24"; # Cursor size
}
