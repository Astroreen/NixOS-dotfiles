{ config, lib, ... }:
let
  # Every field mkDefault, so a host overrides it without lib.mkForce.
  defaults = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault));

  # Catchall mouse binds interrupt the launcher (ignore mods, non-consuming)
  launcherInterruptMouse = lib.listToAttrs (
    map
      (button: {
        name = "launcherInterrupt-${button}";
        value = {
          key = "SUPER + ${button}";
          global = "caelestia:launcherInterrupt";
          hyprland.flags = {
            ignore_mods = true;
            non_consuming = true;
          };
        };
      })
      [
        "mouse:272"
        "mouse:273"
        "mouse:274"
        "mouse:275"
        "mouse:276"
        "mouse:277"
        "mouse_up"
        "mouse_down"
      ]
  );
in
{
  imports = [
    ../../../../../modules/wm/keybinds # custom.keybinds
  ];

  # Same bind names as ../dux/binds.nix, so a host override such as
  # custom.keybinds.binds.launcher.key applies to whichever shell is on.
  # Off while both shells are on, so the clash is reported by the
  # modules/wm/shell assertion rather than as conflicting bind definitions.
  custom.keybinds.binds = lib.mkIf (config.custom.caelestia.enable && !config.custom.dux.enable) (
    defaults (
      {
        # Menu/Launcher
        launcher = {
          key = "SUPER + Q";
          global = "caelestia:launcher";
        };
        dashboard = {
          key = "SUPER + K";
          global = "caelestia:showall";
        };
        # Notification sidebar
        notifications = {
          key = "SUPER + N";
          global = "caelestia:sidebar";
        };
        lock = {
          key = "SUPER + L";
          global = "caelestia:lock";
        };
        sessionMenu = {
          key = "CTRL + ALT + Delete";
          global = "caelestia:session";
        };

        # Caelestia utilities
        restartShell = {
          key = "CTRL + SUPER + SHIFT + R";
          exec = "systemctl --user restart caelestia";
        };
        screenshot = {
          key = "Print";
          global = "caelestia:screenshotFreeze";
        };
        # Disable closing program with CTRL Q
        blockCtrlQ = {
          key = "CTRL + Q";
          global = "caelestia:launcherInterrupt";
        };
        specialWorkspace = {
          key = "SUPER + S";
          exec = "caelestia toggle specialws";
        };

        # Media, locked (work while session locked)
        mediaStop = {
          key = "XF86AudioStop";
          global = "caelestia:mediaStop";
          locked = true;
        };
        mediaToggle = {
          key = "CTRL + SUPER + S";
          global = "caelestia:mediaToggle";
          locked = true;
        };
        mediaNext = {
          key = "CTRL + SUPER + Equal";
          global = "caelestia:mediaNext";
          locked = true;
        };
        mediaPrev = {
          key = "CTRL + SUPER + Minus";
          global = "caelestia:mediaPrev";
          locked = true;
        };

        # Fire alongside the plain brightnessctl binds (../../keybinds)
        shellBrightnessUp = {
          key = "XF86MonBrightnessUp";
          global = "caelestia:brightnessUp";
          locked = true;
        };
        shellBrightnessDown = {
          key = "XF86MonBrightnessDown";
          global = "caelestia:brightnessDown";
          locked = true;
        };

        clearNotifications = {
          key = "CTRL + ALT + C";
          global = "caelestia:clearNotifs";
          locked = true;
        };

        # Lock restore: bring the shell back if it died while locked
        restoreShell = {
          key = "SUPER + ALT + L";
          exec = "caelestia shell -d";
          locked = true;
        };
        restoreLock = {
          key = "SUPER + ALT + L";
          global = "caelestia:lock";
          locked = true;
        };
      }
      // launcherInterruptMouse
    )
  );
}
