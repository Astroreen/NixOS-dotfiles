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
        "QT_QPA_PLATFORM=wayland"
        "XDG_SESSION_TYPE=wayland"
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

    wayland.windowManager.hyprland.settings = lib.mkIf cfg.enableDefaultKeyboardBinds (
      let
        lua = lib.generators.mkLuaInline;
        exec = cmd: lua "hl.dsp.exec_cmd(\"${cmd}\")";
        # NOTE: `hyprctl dispatch <legacy args>` (space-separated, non-Lua) is
        # rejected under Lua config ("')' expected near ..."), so dispatchers
        # without a plain shell-command equivalent must use their real
        # hl.dsp.* function directly instead of shelling out.
        global = name: lua "hl.dsp.global(\"${name}\")";
        toWorkspace = ws: lua "hl.dsp.window.move({ workspace = \"${ws}\" })";
        focus = dir: lua "hl.dsp.focus({ direction = \"${dir}\" })";
        swap = dir: lua "hl.dsp.window.swap({ direction = \"${dir}\" })";
      in
      {
        bind = [
          { _args = [ "SUPER + Q" (global "caelestia:launcher") ]; } # Menu/Launcher

          # Caelestia shell integration
          { _args = [ "SUPER + K" (global "caelestia:showall") ]; }
          { _args = [ "SUPER + L" (global "caelestia:lock") ]; }
          { _args = [ "SUPER + SHIFT + L" (exec "systemctl suspend-then-hibernate") ]; }
          { _args = [ "CTRL + ALT + Delete" (global "caelestia:session") ]; }
          { _args = [ "SUPER + M" (lua "hl.dsp.exit()") ]; }

          # Caelestia utilities
          { _args = [ "SUPER + Period" (exec "pkill fuzzel || caelestia emoji -p") ]; } # Emoji picker
          { _args = [ "CTRL + SUPER + SHIFT + R" (exec "systemctl --user restart caelestia") ]; } # Kill/restart Caelestia shell
          { _args = [ "Print" (global "caelestia:screenshotFreeze") ]; } # Screenshots (enhanced from original)
          { _args = [ "SUPER + SHIFT + C" (exec "hyprpicker -a") ]; } # Color picker (just like from powertoys on windows)
          { _args = [ "CTRL + Q" (global "caelestia:launcherInterrupt") ]; } # Disable closing program with CTRL Q

          # Special workspaces (from Caelestia)
          { _args = [ "SUPER + S" (exec "caelestia toggle specialws") ]; }
          { _args = [ "CTRL + SUPER + up" (toWorkspace "special:special") ]; }
          { _args = [ "CTRL + SUPER + down" (toWorkspace "e+0") ]; }

          # Enhanced window movement from Caelestia
          { _args = [ "SUPER + SHIFT + left" (swap "left") ]; }
          { _args = [ "SUPER + SHIFT + right" (swap "right") ]; }
          { _args = [ "SUPER + SHIFT + up" (swap "up") ]; }
          { _args = [ "SUPER + SHIFT + down" (swap "down") ]; }
          { _args = [ "SUPER + left" (focus "left") ]; }
          { _args = [ "SUPER + right" (focus "right") ]; }
          { _args = [ "SUPER + up" (focus "up") ]; }
          { _args = [ "SUPER + down" (focus "down") ]; }

          # Catchall mouse binds to interrupt launcher (ignore mods, non-consuming)
          {
            _args = [
              "SUPER + mouse:272"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse:273"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse:274"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse:275"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse:276"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse:277"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse_up"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }
          {
            _args = [
              "SUPER + mouse_down"
              (global "caelestia:launcherInterrupt")
              {
                ignore_mods = true;
                non_consuming = true;
              }
            ];
          }

          # Media controls (original + Caelestia enhancements), locked (work while session locked)
          {
            _args = [
              "XF86AudioNext"
              (exec "playerctl next")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioPause"
              (exec "playerctl play-pause")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioPlay"
              (exec "playerctl play-pause")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioPrev"
              (exec "playerctl previous")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioStop"
              (global "caelestia:mediaStop")
              { locked = true; }
            ];
          }

          {
            _args = [
              "CTRL + SUPER + S"
              (global "caelestia:mediaToggle")
              { locked = true; }
            ];
          }
          {
            _args = [
              "CTRL + SUPER + Equal"
              (global "caelestia:mediaNext")
              { locked = true; }
            ];
          }
          {
            _args = [
              "CTRL + SUPER + Minus"
              (global "caelestia:mediaPrev")
              { locked = true; }
            ];
          }

          {
            _args = [
              "XF86MonBrightnessUp"
              (global "caelestia:brightnessUp")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessDown"
              (global "caelestia:brightnessDown")
              { locked = true; }
            ];
          }

          {
            _args = [
              "CTRL + ALT + C"
              (global "caelestia:clearNotifs")
              { locked = true; }
            ];
          }

          # Lock restore
          {
            _args = [
              "SUPER + ALT + L"
              (exec "caelestia shell -d")
              { locked = true; }
            ];
          }
          {
            _args = [
              "SUPER + ALT + L"
              (global "caelestia:lock")
              { locked = true; }
            ];
          }

          # Test notification (message simplified during hyprlang->Lua migration to avoid
          # triple-nested quote escaping; same key/purpose as before)
          {
            _args = [
              "SUPER + ALT + f12"
              (exec "notify-send -u low -i dialog-information-symbolic 'Test notification' 'Truncation and wrapping test message' -a Shell")
              { locked = true; }
            ];
          }
        ];
      }
    );
  };
}
