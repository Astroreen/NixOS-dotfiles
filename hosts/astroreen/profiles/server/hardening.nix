{ lib, ... }:
{
  # Key-only SSH (keys come from the host's authorized_keys).
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce false;
    KbdInteractiveAuthentication = false;
  };

  # Accounts have no password on a fresh install, and remote deploys need
  # non-interactive sudo. Only wheel (astroreen) gets it; `agent` is not in wheel.
  security.sudo.wheelNeedsPassword = false;
}
