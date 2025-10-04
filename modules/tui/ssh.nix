{ pkgs, config, ... }:
{
  programs.ssh = {
    enable = true;

    # Additional SSH config options
    extraConfig = ''
      AddKeysToAgent yes
    '';
    
    # Define hosts
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/github-astroreen";
        user = "git";
      };
    };
  };

  services.ssh-agent.enable = true;
}
