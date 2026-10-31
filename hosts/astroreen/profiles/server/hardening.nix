{ lib, ... }:
{
  # Key-only SSH (keys come from the host's authorized_keys). Passwordless
  # sudo for wheel (astroreen; `agent` is not in wheel) is in common/base/user.nix.
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce false;
    KbdInteractiveAuthentication = false;
  };
}
