{ pkgs, ... }: {
  # Enable zsh so it could be added to SHELL variable int /etc/shell
  programs.zsh.enable = true;
  
  users.users.astroreen = {
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };
}
