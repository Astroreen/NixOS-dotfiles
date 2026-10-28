{ config, lib, ... }:
let
  # Every field mkDefault, so a host overrides it without lib.mkForce.
  defaults = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault));
in
{
  # Window-manager- and shell-agnostic binds: plain commands only.
  # Compositor dispatchers stay in ../hyprland/settings/binds.nix, shell
  # actions in ../shell/<shell>/binds.nix.
  imports = [
    ../../../../modules/wm/keybinds # custom.keybinds
  ];

  custom.keybinds.binds = defaults {
    suspend = {
      key = "SUPER + SHIFT + L";
      exec = "systemctl suspend-then-hibernate";
    };
    # Color picker (just like from powertoys on windows)
    colorPicker = {
      key = "SUPER + SHIFT + C";
      exec = "hyprpicker -a";
    };

    # Push-to-talk toggle: first SUPER+F9 starts listening, the next
    # press stops and transcribes (daemon `toggle` flips on its state).
    dictation = {
      inherit (config.custom.dictation) enable;
      key = "SUPER + F9";
      exec = "${config.custom.dictation.daemonBin} toggle";
    };

    # Media, locked (work while session locked)
    audioNext = {
      key = "XF86AudioNext";
      exec = "playerctl next";
      locked = true;
    };
    audioPause = {
      key = "XF86AudioPause";
      exec = "playerctl play-pause";
      locked = true;
    };
    audioPlay = {
      key = "XF86AudioPlay";
      exec = "playerctl play-pause";
      locked = true;
    };
    audioPrev = {
      key = "XF86AudioPrev";
      exec = "playerctl previous";
      locked = true;
    };

    # Volume and brightness, locked (+ repeating while held)
    volumeMute = {
      key = "XF86AudioMute";
      exec = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      locked = true;
    };
    volumeUp = {
      key = "XF86AudioRaiseVolume";
      exec = "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+";
      locked = true;
      repeating = true;
    };
    volumeDown = {
      key = "XF86AudioLowerVolume";
      exec = "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
      locked = true;
      repeating = true;
    };
    micMute = {
      key = "XF86AudioMicMute";
      exec = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      locked = true;
      repeating = true;
    };
    brightnessUp = {
      key = "XF86MonBrightnessUp";
      exec = "brightnessctl s 10%+";
      locked = true;
      repeating = true;
    };
    brightnessDown = {
      key = "XF86MonBrightnessDown";
      exec = "brightnessctl s 10%-";
      locked = true;
      repeating = true;
    };

    testNotification = {
      key = "SUPER + ALT + f12";
      exec = "notify-send -u low -i dialog-information-symbolic 'Test notification' 'Truncation and wrapping test message' -a Shell";
      locked = true;
    };
  };
}
