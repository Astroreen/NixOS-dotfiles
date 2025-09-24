{ lib, pkgs, config, ... }:
let

    settingsPath = "${config.home.homeDirectory}/.config/Code/User/settings.json";
    
    # Read existing settings if they exist
    existingSettings = 
        if builtins.pathExists settingsPath
        then builtins.fromJSON (builtins.readFile settingsPath)
        else {};
      
    # Direnv-specific settings to add to vscode
    direnvSettings = {
        # Direnv integration
        "direnv.restart.automatic" = true;
        "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
    };
in
{
    home.packages = with pkgs; [
        devenv
    ];

    programs = {
        direnv = {
            enable = true;
            package = pkgs.direnv;
            enableBashIntegration = true;
            enableFishIntegration = false;
            enableZshIntegration = false;
            enableNushellIntegration = false;
            silent = true;
            nix-direnv.enable = true;
            mise.enable = false;
        };

        vscode = {
            # Merge existing settings with Direnv settings
            profiles.default.userSettings = existingSettings // direnvSettings;
        };
    };
}
