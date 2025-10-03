{ pkgs, config, ... }:
{
  programs.bash.enable = true;

  home.packages = with pkgs; [
    zsh-powerlevel10k
    meslo-lgs-nf # Meslo Nerd Font patched for Powerlevel10k
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      append = true;
      expireDuplicatesFirst = true;
      ignoreAllDups = true;
    };

    # List of paths to autocomplete
    cdpath = [
      "${config.home.homeDirectory}/.local/share/nixos"
      "${config.home.homeDirectory}/Downloads"
      "${config.home.homeDirectory}/Documents"
    ];

    initContent = ''
      # Powerlevel10k theme
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

      # Load p10k config (place your p10k.zsh in ~/.config/home-manager/)
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Uncomment to customize LS_COLORS
      #LS_COLORS='...'
      #export LS_COLORS
    '';

    # Equivalent to .profile
    profileExtra = ''
      # Login shell init
    '';
  };

  home.shellAliases = {
    nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
  };
}
