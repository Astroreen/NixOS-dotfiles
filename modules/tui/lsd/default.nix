{ pkgs, ... }:
{
    programs.lsd = {
        enable = true;
        package = pkgs.lsd;
    };

    home.shellAliases = {
        ls = "lsd";
    };
}