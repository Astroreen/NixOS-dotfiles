# Docker services preconfigured for astroreen's home server. Importing this
# directory enables all of them; secrets come from /var/lib/secrets/*.env,
# created by hand on the host (never in the repo).
_: {
  imports = [
    ../../../../modules/server/services

    ./actual.nix
    ./n8n.nix
    ./nextcloud-aio.nix
    ./pihole.nix
    ./vaultwarden.nix
  ];
}
