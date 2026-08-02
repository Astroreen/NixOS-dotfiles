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
        fastfetch-random
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

      # GUI-like text editing: word jump, word delete, select-all, smart
      # backspace-deletes-selection, deselect-on-move, copy-vs-interrupt,
      # system-clipboard sync.
      (lib.mkOrder 960 ''
        # Force a uniform selection color instead of default "standout"
        # (plain reverse-video). Standout just flips each char's existing
        # fg/bg, so zsh-syntax-highlighting's per-token colors (command=blue,
        # error=red, etc.) bleed through as a multi-colored selection instead
        # of one solid block - that's the glitchy look, not a bug.
        zle_highlight=('region:bg=24,fg=15')

        # Cursor movement: if a selection is active, the first press just
        # collapses the cursor to the selection's edge (GUI behavior) instead
        # of moving one further step from wherever the cursor already sits.
        # Bound to SPECIFIC keys (terminfo where possible) rather than
        # overriding the builtin widget names globally - other zsh machinery
        # (autosuggestions, fzf-tab, syntax-highlighting redraw hooks) also
        # calls widgets like `end-of-line`/`beginning-of-line` internally on
        # every keystroke, and a global override made those internal calls
        # silently clear the selection too, not just real keypresses.
        _move-or-collapse-selection() {
          emulate -L zsh
          local real=$1 dir=$2
          if (( REGION_ACTIVE )); then
            local edge
            if [[ $dir == fwd ]]; then
              (( edge = MARK > CURSOR ? MARK : CURSOR ))
            else
              (( edge = MARK < CURSOR ? MARK : CURSOR ))
            fi
            zle deactivate-region
            CURSOR=$edge
          else
            zle .$real
          fi
        }
        _my-forward-char()  { _move-or-collapse-selection forward-char  fwd }
        _my-backward-char() { _move-or-collapse-selection backward-char back }
        _my-forward-word()  { _move-or-collapse-selection forward-word  fwd }
        _my-backward-word() { _move-or-collapse-selection backward-word back }
        zle -N _my-forward-char
        zle -N _my-backward-char
        zle -N _my-forward-word
        zle -N _my-backward-word

        zmodload -i zsh/terminfo 2>/dev/null
        bindkey "''${terminfo[kcuf1]}" _my-forward-char   # Right
        bindkey "''${terminfo[kcub1]}" _my-backward-char  # Left
        bindkey '^[[1;5C' _my-forward-word                # Ctrl+Right
        bindkey '^[[1;5D' _my-backward-word                # Ctrl+Left
        bindkey '^H' backward-kill-word      # Ctrl+Backspace

        # Ctrl+A selects AND immediately copies to the kill-ring (synced to
        # the system clipboard below) - Ctrl+C can't be used for an explicit
        # "copy selection" trigger: ^C is the tty driver's INTR character,
        # intercepted by the kernel's line discipline and turned into a
        # SIGINT that bypasses zle's keymap entirely before zle ever sees a
        # byte (this is also why zsh's own default emacs keymap binds ^C to
        # undefined-key - Src/Zle/zle_bindings.c). Reliably suppressing INTR
        # only while zle is active was attempted (stty intr undef in a
        # line-init/line-finish hook) and did not work reliably, with a real
        # risk of leaving INTR stuck disabled (breaking real Ctrl+C for
        # foreground processes) if the restore hook is ever skipped - not
        # worth the fragility for this.
        select-all-line() {
          emulate -L zsh
          zle .beginning-of-line
          zle .set-mark-command
          zle .end-of-line
          zle .copy-region-as-kill
        }
        zle -N select-all-line
        bindkey '^A' select-all-line         # Ctrl+A (Home still available for beginning-of-line)

        # Backspace: if a selection is active, delete the whole region
        # (native backward-delete-char/backward-kill-word ignore REGION_ACTIVE).
        smart-backspace() {
          emulate -L zsh
          if (( REGION_ACTIVE )); then
            zle .kill-region
          else
            zle .backward-delete-char
          fi
        }
        zle -N smart-backspace
        bindkey '^?' smart-backspace

        # zsh's kill-ring (CUTBUFFER) is not the OS clipboard. Mirror it to
        # wl-copy on every redraw so Ctrl+A-select / smart-backspace-delete /
        # any kill-word can be pasted outside the terminal too.
        autoload -Uz add-zle-hook-widget
        typeset -g _cutbuffer_last=""
        _sync-cutbuffer-clipboard() {
          [[ "$CUTBUFFER" == "$_cutbuffer_last" ]] && return
          _cutbuffer_last=$CUTBUFFER
          [[ -z "$CUTBUFFER" ]] && return
          (( ''${+commands[wl-copy]} )) && printf '%s' "$CUTBUFFER" | wl-copy >/dev/null 2>&1
        }
        add-zle-hook-widget line-pre-redraw _sync-cutbuffer-clipboard
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
