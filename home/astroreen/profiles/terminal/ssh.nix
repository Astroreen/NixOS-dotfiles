_:
{
  # Enable SSH client and agent
  programs.ssh = {
    enable = true;

    # Additional SSH config options
    extraConfig = ''
      AddKeysToAgent yes
    '';
    
    matchBlocks = {
      # Configures SSH to use ~/.ssh/github-astroreen as the identity file when connecting to github.com as user
      "github.com" = {
        identityFile = "~/.ssh/github-astroreen";
        user = "git";
      };
    };
  };

  services.ssh-agent.enable = true;
}
