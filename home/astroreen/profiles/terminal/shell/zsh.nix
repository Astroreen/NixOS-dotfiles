{
  pkgs,
  config,
  lib,
  ...
}:
{
  # zsh-powerlevel10k and fzf/zoxide are pulled in as `programs.zsh.plugins`
  # / `programs.fzf`/`programs.zoxide` packages below - only the Nerd Font
  # needs to be installed explicitly here.
  home.packages = with pkgs; [
    meslo-lgs-nf
  ];

  # p10k user config (generated via `p10k configure`), sourced from initContent below.
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
        command = "fg=blue,bold";
        alias = "fg=blue,italic";
        builtin = "fg=cyan";
        comment = "fg=8";
        condition = "fg=yellow";
        constant = "fg=yellow";
        error = "fg=red,bold";
        function = "fg=blue,bold";
        keyword = "fg=blue,bold";
        "local-variable" = "fg=blue";
        parameter = "fg=blue";
        path = "fg=grey";
        "single-quoted-argument" = "fg=green";
        "double-quoted-argument" = "fg=green";
        "back-quoted-argument" = "fg=green";
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

    # Plugins fetched/pinned by Nix instead of a runtime plugin manager (zinit) -
    # reproducible, and no more runtime `git clone` that can print to stdout
    # after the instant-prompt block (see initContent note below).
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    # home-manager merges initContent fragments from every module (compinit=570,
    # autosuggestions=700, zoxide=851, plugins=900, fzf=910, ...) by ascending
    # `mkOrder`. Fragments below are explicitly ordered relative to those.
    initContent = lib.mkMerge [
      # fastfetch MUST run before p10k's instant-prompt starts capturing
      # stdout. Anything that prints *after* the instant-prompt block gets
      # baked into the instant-prompt replay cache
      # (~/.cache/p10k-instant-prompt-*.zsh) and is replayed verbatim on the
      # *next* shell start. Since fastfetch's output changes every run
      # (date, CPU, uptime), that stale cached output is what corrupted
      # later terminal rendering (e.g. `lsd`) - see romkatv/powerlevel10k
      # README "How do I configure instant prompt?" (chatty-script example).
      # fastfetch's separator module has no built-in terminal-width auto-fill
      # (only a literal `string` + repeat `length`, see default.nix) - but it
      # does expose a generic `--<module>-<option>` CLI override, so build the
      # separator here from zsh's own live $COLUMNS instead of a fixed string.
      (lib.mkOrder 50 ''
        fastfetch
      '')

      # Enable Powerlevel10k instant prompt. Must stay as close to the top
      # of initContent as possible - only console-output-only code
      # (fastfetch above) may run before it.
      (lib.mkOrder 100 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # p10k user config, sourced right after the theme plugin loads
      # (home-manager sources `plugins` entries at mkOrder 900).
      (lib.mkOrder 901 ''
        source "${config.home.homeDirectory}/.config/powerlevel10k/p10k.zsh"
      '')

      # Completion + fzf-tab styling
      (lib.mkOrder 950 ''
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
        zstyle ':fzf-tab:complete:ls:*' fzf-preview 'lsd $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'
      '')
    ];
  };

  # Shell integrations - replaces manual `eval "$(fzf --zsh)"` /
  # `eval "$(zoxide init --cmd cd zsh)"`. home-manager wires these in at
  # their own correctly-ordered initContent slots (zoxide: 851, fzf: 910).
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  # Optional: Set zsh as default shell
  # Note: On NixOS, you still need system config: users.users.yourname.shell = pkgs.zsh;
  # On non-NixOS: run `chsh -s $(which zsh)` manually
}
