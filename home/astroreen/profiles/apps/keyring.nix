{ config, pkgs, ... }:
{
  # PAM unlocks only the login collection. Keep new application credentials
  # there rather than in a separately password-protected default collection.
  # Existing secrets in other collections need a one-time migration; changing
  # this alias does not move or delete them. Use the API, not a managed
  # keyrings/default file: gnome-keyring caches and rewrites that file itself.
  systemd.user.services.login-keyring-default = {
    Unit = {
      Description = "Use the PAM-unlocked login keyring by default";
      # On a fresh home PAM creates this at the first password login; do not
      # fail during the initial autologin before that has happened.
      ConditionPathExists = "${config.xdg.dataHome}/keyrings/login.keyring";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SetAlias so default /org/freedesktop/secrets/collection/login";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
