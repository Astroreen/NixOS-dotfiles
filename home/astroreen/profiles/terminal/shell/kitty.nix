{ lib, ... }:
{
  programs.kitty = {
    enable = true;
    enableGitIntegration = true;
    shellIntegration.enableZshIntegration = true;
    themeFile = "GruvboxMaterialDarkMedium";

    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 15;
      enable_audio_bell = true;

      # Mouse
      open_url_with = "default";
      copy_on_select = "yes";

      # Tab bar
      tab_bar_style = "powerline";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_powerline_style = "round";

      # Window
      window_padding_width = "10 20 10 20";
    };

    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
      "ctrl+v" = "paste_from_clipboard";
      "ctrl+escape" = "send_text all \\x03";
      # Unmap kitty's default kitty_mod (=ctrl+shift) tab-switching so the
      # raw key reaches the shell instead - zsh's zle uses ctrl+shift+arrow
      # for shift-select-by-word. Mapping to an empty action removes the
      # default binding (kitty's `map <key>` with no action = unmap).
      "ctrl+shift+right" = "";
      "ctrl+shift+left" = "";
      # Moved tab-switching here instead. Note: this overrides kitty's
      # default ctrl+shift+up/down (scroll_line_up/scroll_line_down).
      "ctrl+shift+up" = "next_tab";
      "ctrl+shift+down" = "previous_tab";
    };
  };

  wayland.windowManager.hyprland = {
    settings.window_rule = [
      {
        match.class = "^(kitty)$";
        size = "1300 800";
        float = true;
        center = true;
      }
    ];

    settings.bind = [
      {
        _args = [
          "SUPER + T"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"[float; size 1300 800] kitty\")")
        ];
      } # Terminal
    ];
  };
}
