{ pkgs, ... }:
{
    programs.git = {
        enable = true;
        package = pkgs.git;
        userName = "astroreen";
        userEmail = "astroreen@gmail.com";

        #aliases = {
        #    commit = "commit -m ''";
        #};
    };
}