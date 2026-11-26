# boat.dev CLI + t3boat MCP bridge for astroreen across all hosts.
#
# All hosts route Boat API calls through hercules's tailnet-only reverse proxy
# (`hosts/astroreen/profiles/server/boat-proxy.nix`, exposed at :8318 via its
# root Tailscale Serve unit over a private Unix socket), authenticating with a
# dedicated mode-0600 client token (`~/.config/boat/proxy-token`, never passed
# on argv) so BOAT_API_KEY lives only in `/var/lib/secrets/boat-api-key` on
# hercules and local unprivileged accounts (agent, CI runners) cannot call Boat.
#
# One-time setup (after `deploy switch hercules` + `home switch`):
#   1. On hercules, store BOAT_API_KEY and generate the proxy client token:
#        boat onboard
#        boat api-key create t3boat --preset ci
#        IFS= read -rs key && printf '%s' "$key" | sudo install -D -m 600 /dev/stdin /var/lib/secrets/boat-api-key && unset key
#        python3 -c 'import secrets; print(secrets.token_hex(32), end="")' | sudo install -D -m 600 /dev/stdin /var/lib/secrets/boat-proxy-client-token
#        sudo install -D -m 600 -o astroreen -g users /var/lib/secrets/boat-proxy-client-token ~/.config/boat/proxy-token
#        sudo systemctl start boat-proxy
#   2. Copy the client token to pc / laptop:
#        tok=$(ssh hercules cat ~/.config/boat/proxy-token) && [ -n "$tok" ] && printf '%s' "$tok" | install -D -m 600 /dev/stdin ~/.config/boat/proxy-token && unset tok
#   3. Verify from any host (pc, laptop, hercules):
#        t3boat-mcp doctor
_: {
  imports = [
    ../../../../modules/terminal/ai
  ];

  custom.ai.boat = {
    enable = true;
    proxyUrl = "https://hercules.bumblebee-parrotfish.ts.net:8318";
    defaultSnapshot = "dev-base";
  };
}
