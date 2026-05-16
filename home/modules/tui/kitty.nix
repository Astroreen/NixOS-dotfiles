_: {
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
  };

  wayland.windowManager.hyprland = {
    settings.windowrule = [
      "match:class ^(kitty)$, size 1200 800, float on, center on"
    ];

    submaps.global.settings.bind = [
      "$mod, T, exec, [float; size 1200 800] kitty" # Terminal
    ];
  };
}
