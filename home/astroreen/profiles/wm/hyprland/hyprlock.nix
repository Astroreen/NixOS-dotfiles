{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaper = ../../../common/assets/astronaut.jpg;
  avatar = ../../../common/assets/avatar.jpg;
  font = "JetBrainsMono Nerd Font";

  # Lock once per boot (keyed by kernel boot_id so an explicit logout + manual
  # SDDM login does not prompt twice). Fail closed: if hyprlock exits non-zero
  # before unlocking, terminate the autologin session back to SDDM instead of
  # leaving the desktop unlocked.
  bootLock = pkgs.writeShellScript "hyprlock-boot-lock" ''
    boot_id="$(${pkgs.coreutils}/bin/cat /proc/sys/kernel/random/boot_id)"
    stamp="''${XDG_STATE_HOME:-$HOME/.local/state}/hyprlock-boot-id"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$stamp")"

    if [ "$(${pkgs.coreutils}/bin/cat "$stamp" 2>/dev/null || true)" = "$boot_id" ]; then
      exit 0
    fi
    printf '%s' "$boot_id" > "$stamp"

    if ! ${lib.getExe config.programs.hyprlock.package} --grace 0 --immediate-render --no-fade-in; then
      if [ -n "''${XDG_SESSION_ID:-}" ]; then
        ${pkgs.systemd}/bin/loginctl terminate-session "$XDG_SESSION_ID" || true
      fi
      ${pkgs.procps}/bin/pkill -TERM -x Hyprland || true
    fi
  '';
in
{
  # Boot-time lockscreen paired with SDDM autologin so startup apps load behind
  # an immediately locked screen. In-session locking (SUPER + L) still uses dux.
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = false;
        ignore_empty_input = true;
        immediate_render = true;
      };

      animations = {
        enabled = true;
        bezier = "easeOutQuint, 0.23, 1, 0.32, 1";
        animation = [
          "fadeIn, 0"
          "fadeOut, 1, 3, easeOutQuint"
          "inputFieldDots, 1, 2, easeOutQuint"
        ];
      };

      background = [
        {
          monitor = "";
          path = "${wallpaper}";
          color = "rgb(18, 18, 22)";
          blur_passes = 2;
          blur_size = 5;
          brightness = 0.7;
        }
      ];

      image = [
        {
          monitor = "";
          path = "${avatar}";
          size = 110;
          rounding = -1;
          border_size = 2;
          border_color = "rgba(255, 255, 255, 0.25)";
          position = "0, 60";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(242, 242, 247, 0.95)";
          font_size = 76;
          font_family = font;
          position = "0, 260";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
        }
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%a, %d %b %Y"'';
          color = "rgba(242, 242, 247, 0.72)";
          font_size = 18;
          font_family = font;
          position = "0, 185";
          halign = "center";
          valign = "center";
          shadow_passes = 1;
        }
        {
          monitor = "";
          text = "$LAYOUT[EN,RU,LT]";
          onclick = "hyprctl switchxkblayout all next";
          color = "rgba(242, 242, 247, 0.65)";
          font_size = 13;
          font_family = font;
          position = "0, -105";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "280, 48";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(255, 255, 255, 0.22)";
          inner_color = "rgba(24, 24, 30, 0.75)";
          font_color = "rgb(242, 242, 247)";
          font_family = font;
          check_color = "rgb(138, 180, 248)";
          fail_color = "rgb(242, 139, 130)";
          fade_on_empty = false;
          placeholder_text = ''<span foreground="##a6adc8">Password...</span>'';
          fail_text = "<i>$PAMFAIL <b>($ATTEMPTS)</b></i>";
          rounding = 14;
          position = "0, -50";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
        }
      ];
    };
  };

  # Lock as the very first hyprland.start callback (before autostart apps and
  # graphical-session.target) with zero grace and no fade-in.
  wayland.windowManager.hyprland.settings.on = lib.mkBefore [
    {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline ''
          function()
            hl.exec_cmd("${bootLock}")
          end'')
      ];
    }
  ];
}
