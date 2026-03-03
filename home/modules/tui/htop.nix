{ pkgs, ... }:
{
  programs.htop = {
    enable = true;
    package = pkgs.neohtop;
  };

  # Create a wrapper script with environment variables
  home.packages = [
    (pkgs.writeShellScriptBin "neohtop-fixed" ''
      export GDK_BACKEND=x11
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      exec ${pkgs.neohtop}/bin/NeoHtop "$@"
    '')
  ];

  # Set up proper aliases
  home.shellAliases = {
    htop = "neohtop-fixed";
    NeoHtop = "neohtop-fixed";
  };
}
