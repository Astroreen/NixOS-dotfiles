{ pkgs, ... }:
{
  # You can use this file to setup your shell however you like
  programs.bash.enable = true; # Enable just to apply changes from home.shellAliases = {...};
  home.shell.enableShellIntegration = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
        enable = true;
        theme = "powerlevel10k/powerlevel10k";
    };
  };

  home.shellAliases = {
    nixconfig = "cd ~/.local/share/nixos";
  };
}
