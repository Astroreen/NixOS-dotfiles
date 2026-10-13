# T3 Code: declarative theme + settings + keybindings, synced across hosts.
# The module (home/modules/apps/t3code) owns the options; this profile supplies
# the concrete values. settings/keybindings are plain JSON files so updating is
# a copy from ~/.t3/userdata/ (the module also accepts inline nix values).
{ ... }:
{
  imports = [
    ../../../../modules/apps/t3code
  ];

  custom.t3code = {
    enable = true;

    # Theme files are activation-copied to ~/.t3/userdata/themes/<name>.json.
    themes.gruvbox = ./themes/gruvbox.json;

    # Declarative subset of settings.json (declarative keys win on merge).
    # projectSettingsOverrides / defaultThemeSetAt / environmentIcon are
    # intentionally omitted: host-specific or service-managed.
    settingsFile = ./settings.json;

    # Full keymap; declarative rules win per (key, when).
    keybindingsFile = ./keybindings.json;
  };
}
