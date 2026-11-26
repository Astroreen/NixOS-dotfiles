# Boat.dev API reverse proxy on hercules (:8318, tailnet-only).
# Holds the single BOAT_API_KEY so pc and laptop never need a local Boat key;
# Caddy listens only on a mode-0600 Unix socket inside /run/boat-proxy (0700),
# verifies a dedicated client bearer token (/var/lib/secrets/boat-proxy-client-token,
# never passed via argv and unreadable by `agent` or CI runners), and a
# companion root systemd unit exposes it over Tailscale HTTPS :8318.
#
# One-time setup on hercules:
#   1. Sign in directly to boat.dev and create a scoped API key:
#        boat onboard
#        boat api-key create t3boat --preset ci
#   2. Store the Boat API key root-only without recording it in shell history:
#        IFS= read -rs key && printf '%s' "$key" | sudo install -D -m 600 /dev/stdin /var/lib/secrets/boat-api-key && unset key
#   3. Generate the dedicated client bearer token and copy it to astroreen on each host:
#        python3 -c 'import secrets; print(secrets.token_hex(32), end="")' | sudo install -D -m 600 /dev/stdin /var/lib/secrets/boat-proxy-client-token
#        sudo install -D -m 600 -o astroreen -g users /var/lib/secrets/boat-proxy-client-token /home/astroreen/.config/boat/proxy-token
#        # On pc / laptop:
#        #   tok=$(ssh hercules cat ~/.config/boat/proxy-token) && [ -n "$tok" ] && printf '%s' "$tok" | install -D -m 600 /dev/stdin ~/.config/boat/proxy-token && unset tok
#   4. Start the proxy (also starts boat-proxy-tailscale-serve):
#        sudo systemctl start boat-proxy
#   5. Verify from any tailnet host:
#        t3boat-mcp doctor
_: {
  imports = [
    ../../../modules/server/boat-proxy.nix
  ];

  custom.services.boatProxy.enable = true;
}
