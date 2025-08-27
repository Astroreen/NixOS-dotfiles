{ pkgs, ... }:
{
    programs.vscode = {
        enable = true;
        package = pkgs.vscode;

        profiles.default.userSettings = import ./settings.nix;
    };
}
