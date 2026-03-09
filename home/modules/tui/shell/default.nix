{ pkgs, config, ... }:
{
  imports = [
    ./zsh.nix
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
      };

      #aliases = {
      #    commit = "commit -m ''";
      #};
    };

    fd.enable = true;
  };

  home.shellAliases = {
    nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
    cat = "bat";
  };
}
