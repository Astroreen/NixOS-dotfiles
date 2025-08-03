{ pkgs, ... }: 
{
    programs.htop = {
        enable = true;
        package = pkgs.neohtop;
    };

    home.shellAliases = {
        htop = "NeoHtop";
    };
}