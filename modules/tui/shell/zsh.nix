{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    zsh-powerlevel10k
    meslo-lgs-nf
    fzf
    zoxide
  ];

  # Copy p10k.zsh to home directory
  home.file.".config/powerlevel10k/p10k.zsh".source = ./p10k.zsh;

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
        "regexp"
        "root"
      ];
      styles = {
        command = "fg=cyan,bold";
        alias = "fg=magenta,bold";
        builtin = "fg=cyan";
        comment = "fg=green";
        condition = "fg=yellow";
        constant = "fg=yellow";
        error = "fg=red,bold";
        function = "fg=blue,bold";
        keyword = "fg=magenta,bold";
        "local-variable" = "fg=blue";
        parameter = "fg=blue";
        path = "fg=green";
        "single-quoted-argument" = "fg=yellow";
        "double-quoted-argument" = "fg=yellow";
        "back-quoted-argument" = "fg=yellow";
        redirection = "fg=yellow,bold";
        globbing = "fg=cyan,bold";
        "history-expansion" = "fg=magenta";
        "assign" = "fg=blue";
      };
      patterns = {
        "rm -rf /" = "fg=white,bold,bg=red";
      };
    };

    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Keybindings
    defaultKeymap = "emacs";

    initContent = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      ZINIT_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
      if [[ ! -d $ZINIT_HOME ]]; then
        mkdir -p "$(dirname $ZINIT_HOME)"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
      fi

      source "''${ZINIT_HOME}/zinit.zsh"

      # Add in zsh plugins
      zinit light Aloxaf/fzf-tab

      zinit cdreplay -q # replay all cached completions

      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${config.home.homeDirectory}/.config/powerlevel10k/p10k.zsh

      # Keybindings
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'

      # Shell integrations
      eval "$(fzf --zsh)"
      eval "$(zoxide init --cmd cd zsh)"
    '';
  };

  # Optional: Set zsh as default shell
  # Note: On NixOS, you still need system config: users.users.yourname.shell = pkgs.zsh;
  # On non-NixOS: run `chsh -s $(which zsh)` manually
}
