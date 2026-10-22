{ pkgs, config, ... }:
{
  # Default choices (kitty.nix is imported by common/desktop.nix)
  imports = [
    ./zsh.nix
    ./fastfetch.nix
  ];

  # Apply changes through home-manager and nixos system-wide configuration
  programs = {
    bash.enable = true;
    bash.enableCompletion = true;

    lsd = {
      enable = true;
      package = pkgs.lsd;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        batgrep
        batwatch
      ];
    };

    git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user.name = "astroreen";
        user.email = "astroreen@gmail.com";
        credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        credential."https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };

      #aliases = {
      #    commit = "commit -m ''";
      #};
    };

    fd.enable = true;
  };

  home = {
    packages = with pkgs; [
      pkgs.gh # GitHub CLI - required by oh-my-openagent's GitHub automation features
    ];
    
    shellAliases = {
      nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
      cat = "bat";
    };
  };
}
