# Generic Hyprland helpers (options only; profiles supply concrete values).
{ lib, ... }:
{
  options.custom.hyprland.postUnlockExec = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      Hyprland `hl.exec_cmd` commands (supporting `[rules]` prefixes) launched
      after the boot-time lockscreen unlocks so the login keyring is already
      open via PAM. On subsequent logins in the same boot, they launch
      immediately.
    '';
  };
}
