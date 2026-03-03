{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "astroreen";
      user.email = "astroreen@gmail.com";
    };

    #aliases = {
    #    commit = "commit -m ''";
    #};
  };
}
