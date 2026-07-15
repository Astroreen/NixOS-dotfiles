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
    };
  };

  wayland.windowManager.hyprland = {
    settings.window_rule = [
      {
        match.class = "^(kitty)$";
        size = "1200 800";
        float = true;
        center = true;
      }
    ];

    settings.bind = [
      {
        _args = [
          "SUPER + T"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"[float; size 1200 800] kitty\")")
        ];
      } # Terminal
    ];
  };
}
