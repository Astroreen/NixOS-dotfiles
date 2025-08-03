{ pkgs, ... }:
{
    programs.bat = {
        enable = true;
        package = pkgs.bat;
    };

    home.shellAliases = {
        cat = "bat";
    };

    home.sessionVariables = {
        MANPAGER = "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'";
    };
}