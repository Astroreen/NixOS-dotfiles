# T3 Code: declarative theme + settings + keybindings, synced across hosts.
# The module (home/modules/apps/t3code) owns the options; this profile supplies
# the concrete values. settings/client-settings/keybindings/themes are plain
# JSON files refreshed from a live host with `sync-t3code-config [--host <h>]`
# (scripts/sync-t3code-config.py drops host-specific and secret keys).
{ lib, ... }:
{
  imports = [
    ../../../../modules/apps/t3code
  ];

  custom.t3code = {
    enable = true;

    # Every ./themes/<name>.json is activation-copied to
    # ~/.t3/userdata/themes/<name>.json, so synced themes need no edit here.
    themes =
      lib.mapAttrs' (file: _: lib.nameValuePair (lib.removeSuffix ".json" file) (./themes + "/${file}"))
        (
          lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".json" file) (
            builtins.readDir ./themes
          )
        );

    # Declarative subset of settings.json (declarative top-level keys win on
    # merge). project*Overrides / defaultThemeSetAt / environmentIcon are
    # intentionally omitted: host-specific or service-managed.
    settingsFile = ./settings.json;

    # Desktop UI settings (fonts, contrast, diff layout, notifications, ...),
    # minus onboarding/browser-profile/per-project keys.
    clientSettingsFile = ./client-settings.json;

    # Full keymap; declarative rules win per (key, when).
    keybindingsFile = ./keybindings.json;

    # Background server (systemd user service). Disabled by default; enabling
    # runs `t3 serve` at boot and keeps the server alive after the desktop app
    # closes.
    # Note: Switch off the desktop app's Local environment (Settings →
    # Connections); the app otherwise spawns a second server on the same
    # state dir (~/.t3). Then connect the app to this server via pairing.
    service = {
      enable = lib.mkDefault false;
      host = "0.0.0.0";
      port = 3773;
      extraArgs = [ ];
      restart = "always";
      restartSec = 5;
    };
  };
}
