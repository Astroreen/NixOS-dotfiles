{ config, lib, ... }:
let
  # `dms ipc call <target> <function>`; `dms ipc` lists the targets.
  ipc = args: "dms ipc call ${args}";

  # Every field mkDefault, so a host overrides it without lib.mkForce.
  defaults = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault));
in
{
  imports = [
    ../../../../../modules/wm/keybinds # custom.keybinds
  ];

  # Same bind names and keys as ../caelestia/binds.nix, so muscle memory and
  # host overrides (custom.keybinds.binds.<name>) carry over between shells.
  # Off while both shells are on, so the clash is reported by the
  # modules/wm/shell assertion rather than as conflicting bind definitions.
  custom.keybinds.binds =
    lib.mkIf (config.custom.dux.enable && !config.custom.caelestia.enable)
      (defaults {
        # Menu/Launcher
        launcher = {
          key = "SUPER + Q";
          exec = ipc "spotlight toggle";
        };
        dashboard = {
          key = "SUPER + K";
          exec = ipc ''dash toggle ""'';
        };
        # Notification center
        notifications = {
          key = "SUPER + N";
          exec = ipc "notifications toggle";
        };
        lock = {
          key = "SUPER + L";
          exec = ipc "lock lock";
        };
        sessionMenu = {
          key = "CTRL + ALT + Delete";
          exec = ipc "powermenu toggle";
        };

        # Dux utilities
        settings = {
          key = "SUPER + Comma";
          exec = ipc "settings focusOrToggle";
        };
        restartShell = {
          key = "CTRL + SUPER + SHIFT + R";
          exec = "systemctl --user restart dms";
        };
        # Region select, copied to clipboard and saved
        screenshot = {
          key = "Print";
          exec = "dms screenshot";
        };
        # Disable closing program with CTRL Q
        blockCtrlQ = {
          key = "CTRL + Q";
          exec = ipc "spotlight close";
        };
        specialWorkspace = {
          key = "SUPER + S";
          hyprland.dispatch = "hl.dsp.workspace.toggle_special()";
        };

        # Media, locked (work while session locked)
        mediaStop = {
          key = "XF86AudioStop";
          exec = "playerctl stop";
          locked = true;
        };
        mediaToggle = {
          key = "CTRL + SUPER + S";
          exec = ipc "mpris playPause";
          locked = true;
        };
        mediaNext = {
          key = "CTRL + SUPER + Equal";
          exec = ipc "mpris next";
          locked = true;
        };
        mediaPrev = {
          key = "CTRL + SUPER + Minus";
          exec = ipc "mpris previous";
          locked = true;
        };

        clearNotifications = {
          key = "CTRL + ALT + C";
          exec = ipc "notifications clearAll";
          locked = true;
        };

        # Lock restore: bring the shell back if it died while locked
        restoreShell = {
          key = "SUPER + ALT + L";
          exec = "systemctl --user start dms";
          locked = true;
        };
        restoreLock = {
          key = "SUPER + ALT + L";
          exec = ipc "lock lock";
          locked = true;
        };
      });
}
