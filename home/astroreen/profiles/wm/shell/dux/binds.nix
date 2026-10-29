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
          description = "App launcher";
          key = "SUPER + Q";
          exec = ipc "spotlight toggle";
        };
        dashboard = {
          description = "Dashboard";
          key = "SUPER + K";
          exec = ipc ''dash toggle ""'';
        };
        # Notification center
        notifications = {
          description = "Notification center";
          key = "SUPER + N";
          exec = ipc "notifications toggle";
        };
        lock = {
          description = "Lock screen";
          key = "SUPER + L";
          exec = ipc "lock lock";
        };
        sessionMenu = {
          description = "Power / session menu";
          key = "CTRL + ALT + Delete";
          exec = ipc "powermenu toggle";
        };

        # Dux utilities
        settings = {
          description = "Shell settings";
          key = "SUPER + I";
          exec = ipc "settings focusOrToggle";
        };
        # emojiPicker plugin (replaces the rofi picker, see profiles/apps/emoji-picker)
        emoji = {
          description = "Emoji picker";
          key = "SUPER + Period";
          exec = ipc "emojiPicker toggle";
        };
        # Dux clipboard history (replaces copyq, see profiles/apps/clipboard.nix)
        clipboard = {
          description = "Clipboard history";
          key = "SUPER + V";
          exec = ipc "clipboard toggle";
        };
        restartShell = {
          description = "Restart shell";
          key = "CTRL + SUPER + SHIFT + R";
          exec = "systemctl --user restart dms";
        };
        # QuickCapture plugin menu: capture modes, OCR/QR, screen recording
        quickCapture = {
          description = "QuickCapture menu (capture, OCR, record)";
          key = "Print";
          exec = ipc "quickCapture toggle";
        };
        # Region select, then annotate in satty (via the `swappy` shim from
        # profiles/apps/screenshot.nix: Enter copies + saves to
        # ~/Pictures/Screenshots). grim + slurp, not `dms screenshot`: dux
        # 2.0 ignores output transforms, so rotated monitors come out
        # sideways/squashed. Esc while selecting cancels both.
        screenshot = {
          description = "Region screenshot to satty";
          key = "SUPER + Print";
          exec = ''f="$XDG_RUNTIME_DIR/screenshot.png"; grim -g "$(slurp -d)" "$f" && swappy -f "$f"'';
        };
        # Disable closing program with CTRL Q
        blockCtrlQ = {
          description = "Block Ctrl+Q (no accidental app quit)";
          key = "CTRL + Q";
          exec = ipc "spotlight close";
        };
        specialWorkspace = {
          description = "Toggle special workspace";
          key = "SUPER + S";
          hyprland.dispatch = "hl.dsp.workspace.toggle_special()";
        };

        # Media, locked (work while session locked)
        mediaStop = {
          description = "Stop playback";
          key = "XF86AudioStop";
          exec = "playerctl stop";
          locked = true;
        };
        mediaToggle = {
          description = "Play / pause";
          key = "CTRL + SUPER + S";
          exec = ipc "mpris playPause";
          locked = true;
        };
        mediaNext = {
          description = "Next track";
          key = "CTRL + SUPER + Equal";
          exec = ipc "mpris next";
          locked = true;
        };
        mediaPrev = {
          description = "Previous track";
          key = "CTRL + SUPER + Minus";
          exec = ipc "mpris previous";
          locked = true;
        };

        clearNotifications = {

          description = "Clear all notifications";
          key = "CTRL + ALT + C";
          exec = ipc "notifications clearAll";
          locked = true;
        };

        # Lock restore: bring the shell back if it died while locked
        restoreShell = {
          description = "Start shell if it died while locked";
          key = "SUPER + ALT + L";
          exec = "systemctl --user start dms";
          locked = true;
        };
        restoreLock = {
          description = "Re-lock session";
          key = "SUPER + ALT + L";
          exec = ipc "lock lock";
          locked = true;
        };
      });
}
