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
          description = "App launcher";
          key = "SUPER + Q";
          global = "caelestia:launcher";
        };
        dashboard = {
          description = "Dashboard";
          key = "SUPER + K";
          global = "caelestia:showall";
        };
        # Notification sidebar
        notifications = {
          description = "Notification center";
          key = "SUPER + N";
          global = "caelestia:sidebar";
        };
        lock = {
          description = "Lock screen";
          key = "SUPER + L";
          global = "caelestia:lock";
        };
        sessionMenu = {
          description = "Power / session menu";
          key = "CTRL + ALT + Delete";
          global = "caelestia:session";
        };

        # Caelestia utilities
        restartShell = {
          description = "Restart shell";
          key = "CTRL + SUPER + SHIFT + R";
          exec = "systemctl --user restart caelestia";
        };
        screenshot = {
          description = "Region screenshot to satty";
          key = "Print";
          global = "caelestia:screenshotFreeze";
        };
        # Disable closing program with CTRL Q
        blockCtrlQ = {
          description = "Block Ctrl+Q (no accidental app quit)";
          key = "CTRL + Q";
          global = "caelestia:launcherInterrupt";
        };
        specialWorkspace = {
          description = "Toggle special workspace";
          key = "SUPER + S";
          exec = "caelestia toggle specialws";
        };

        # Media, locked (work while session locked)
        mediaStop = {
          description = "Stop playback";
          key = "XF86AudioStop";
          global = "caelestia:mediaStop";
          locked = true;
        };
        mediaToggle = {
          description = "Play / pause";
          key = "CTRL + SUPER + S";
          global = "caelestia:mediaToggle";
          locked = true;
        };
        mediaNext = {
          description = "Next track";
          key = "CTRL + SUPER + Equal";
          global = "caelestia:mediaNext";
          locked = true;
        };
        mediaPrev = {
          description = "Previous track";
          key = "CTRL + SUPER + Minus";
          global = "caelestia:mediaPrev";
          locked = true;
        };

        # Fire alongside the plain brightnessctl binds (../../keybinds)
        shellBrightnessUp = {
          description = "Brightness up";
          key = "XF86MonBrightnessUp";
          global = "caelestia:brightnessUp";
          locked = true;
        };
        shellBrightnessDown = {
          description = "Brightness down";
          key = "XF86MonBrightnessDown";
          global = "caelestia:brightnessDown";
          locked = true;
        };

        clearNotifications = {

          description = "Clear all notifications";
          key = "CTRL + ALT + C";
          global = "caelestia:clearNotifs";
          locked = true;
        };

        # Lock restore: bring the shell back if it died while locked
        restoreShell = {
          description = "Start shell if it died while locked";
          key = "SUPER + ALT + L";
          exec = "caelestia shell -d";
          locked = true;
        };
        restoreLock = {
          description = "Re-lock session";
          key = "SUPER + ALT + L";
          global = "caelestia:lock";
          locked = true;
        };
      }
      // launcherInterruptMouse
    )
  );
}
