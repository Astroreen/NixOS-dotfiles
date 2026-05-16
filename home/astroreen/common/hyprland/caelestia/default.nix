{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.custom.caelestia;
in
{

  options = with lib; {
    custom.caelestia = {
      enable = mkEnableOption "Enable Caelestia shell configuration";
      enableDefaultKeyboardBinds = mkEnableOption "Enable default keyboard binds for caelestia";
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Caelestia shell settings";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    programs.caelestia = {
      settings = { }; # keep empty so official module skips writing shell.json
      extraConfig = ""; # keep empty
      systemd.environment = [
        "QT_QPA_PLATFORM=wayland;xcb"
        "XDG_SESSION_TYPE=wayland;xcb"
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_DESKTOP=Hyprland"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "WAYLAND_DISPLAY=wayland-1"
        "QUICKSHELL_ENABLE_PORTAL=1"
      ];
    };

    # Home activation is used here to not symlink file into nix store, thus making it writable
    home.activation.caelestiaConfig =
      let
        # Additional configuration
        overrides = {
          paths = {
            mediaGif = ../../assets/kirby-groove.gif;
            sessionGif = ../../assets/evernight-dance.gif;
          };
        };
        mergedConfig = lib.recursiveUpdate cfg.settings overrides;
        configFile = pkgs.writeText "caelestia-config" (builtins.toJSON mergedConfig);
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONF="$HOME/.config/caelestia/shell.json"
        NEW=${configFile}

        if [ ! -f "$CONF" ] || ! diff -q "$CONF" "$NEW" > /dev/null 2>&1; then
          cp "$NEW" "$CONF"
          chmod 644 "$CONF"
          systemctl --user restart caelestia || true
        fi
      '';

    wayland.windowManager.hyprland.submaps.global.settings = lib.mkIf cfg.enableDefaultKeyboardBinds {
      bind = [
        "$mod, Q, global, caelestia:launcher" # Menu/Launcher

        # Caelestia shell integration
        "$mod, K, global, caelestia:showall"
        "$mod, L, global, caelestia:lock"
        "$mod SHIFT, L, exec, systemctl suspend-then-hibernate"
        "CTRL ALT, Delete, global, caelestia:session"
        "$mod, M, exit,"

        # Caelestia utilities
        "$mod, Period, exec, pkill fuzzel || caelestia emoji -p" # Emoji picker
        "CTRL $mod SHIFT, R, exec, systemctl --user restart caelestia" # Kill/restart Caelestia shell
        ", PRINT, global, caelestia:screenshotFreeze" # Screenshots (enhanced from original)
        "$mod SHIFT, C, exec, hyprpicker -a" # Color picker (just like from powertoys on windows)
        "CTRL, Q, global, caelestia:launcherInterrupt" # Disable closing program with CTRL Q

        # Special workspaces (from Caelestia)
        "$mod, S, exec, caelestia toggle specialws"
        "CTRL $mod, up, movetoworkspace, special:special"
        "CTRL $mod, down, movetoworkspace, e+0"

        # Enhanced window movement from Caelestia
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ];

      bindin = [
        # "$mod, catchall, global, caelestia:launcherInterrupt"
        "$mod, mouse:272, global, caelestia:launcherInterrupt"
        "$mod, mouse:273, global, caelestia:launcherInterrupt"
        "$mod, mouse:274, global, caelestia:launcherInterrupt"
        "$mod, mouse:275, global, caelestia:launcherInterrupt"
        "$mod, mouse:276, global, caelestia:launcherInterrupt"
        "$mod, mouse:277, global, caelestia:launcherInterrupt"
        "$mod, mouse_up, global, caelestia:launcherInterrupt"
        "$mod, mouse_down, global, caelestia:launcherInterrupt"
      ];

      bindl = [
        # Media controls (original + Caelestia enhancements)
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, global, caelestia:mediaStop"

        # Enhanced media with Caelestia
        "CTRL $mod, S, global, caelestia:mediaToggle"
        "CTRL $mod, Equal, global, caelestia:mediaNext"
        "CTRL $mod, Minus, global, caelestia:mediaPrev"

        # Brightness
        ", XF86MonBrightnessUp, global, caelestia:brightnessUp"
        ", XF86MonBrightnessDown, global, caelestia:brightnessDown"

        # Notifications
        "CTRL ALT, C, global, caelestia:clearNotifs"

        # Lock restore
        "$mod ALT, L, exec, caelestia shell -d"
        "$mod ALT, L, global, caelestia:lock"

        # Test notification
        "$mod ALT, f12, exec, notify-send -u low -i dialog-information-symbolic 'Test notification' \"Here's a really long message to test truncation and wrapping\\nYou can middle click or flick this notification to dismiss it!\" -a 'Shell' -A \"Test1=I got it!\" -A \"Test2=Another action\""
      ];
    };
  };
}
