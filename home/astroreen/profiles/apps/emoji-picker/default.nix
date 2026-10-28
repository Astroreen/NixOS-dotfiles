{ pkgs, lib, ... }:
let
  # Emoji data comes from rofimoji's bundled CSVs; rofimoji itself is not used
  # because its rofi script mode types while rofi still holds the keyboard.
  emoji-picker = pkgs.writers.writePython3Bin "emoji-picker" { flakeIgnore = [ "E501" ]; } (
    builtins.replaceStrings
      [ "@rofi@" "@wtype@" "@wlCopy@" "@theme@" "@rofimoji@" ]
      [
        (lib.getExe pkgs.rofi)
        (lib.getExe pkgs.wtype)
        (lib.getExe' pkgs.wl-clipboard "wl-copy")
        "${./theme.rasi}"
        "${pkgs.rofimoji}"
      ]
      (builtins.readFile ./emoji-picker.py)
  );
in
{
  # Emoji picker on SUPER + Period: rofi grid, category tabs (Shift + Left/Right),
  # most used emojis first in the 🕘 tab. Replaces `caelestia emoji -p`.
  home.packages = [ emoji-picker ];

  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        "SUPER + Period"
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"pkill -x rofi || emoji-picker\")")
      ];
    } # Emoji picker
  ];
}
