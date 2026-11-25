# CLIProxyAPI: unified local/tailnet OpenAI/Anthropic/Gemini API proxy backed
# by OAuth subscription logins (Claude Code, ChatGPT Codex, Google Antigravity).
#
# Secrets (root:root, 0600 — created by hand on the host, never in the repo):
#   /var/lib/secrets/cliproxyapi-api-key         client bearer / X-Api-Key
#   /var/lib/secrets/cliproxyapi-management-key  management API & Web UI password
#
# Generate both keys once on the host:
#   python3 -c 'import secrets; print(secrets.token_hex(32), end="")' | sudo install -D -m 600 /dev/stdin /var/lib/secrets/cliproxyapi-api-key
#   python3 -c 'import secrets; print(secrets.token_hex(32), end="")' | sudo install -D -m 600 /dev/stdin /var/lib/secrets/cliproxyapi-management-key
#
# Copy the client API key for astroreen's local CLI clients (and to laptop/pc):
#   sudo install -D -m 600 -o astroreen -g users \
#     /var/lib/secrets/cliproxyapi-api-key /home/astroreen/.config/cliproxyapi/api-key
#
# Sign in subscriptions (either via the Web UI over Tailscale at
# https://hercules.tail15a705.ts.net:8317/management.html, or from the CLI):
#   sudo -u cliproxyapi cliproxyapi -config /var/lib/cliproxyapi/config.yaml --claude-login --no-browser
#   sudo -u cliproxyapi cliproxyapi -config /var/lib/cliproxyapi/config.yaml --codex-device-login
#   sudo -u cliproxyapi cliproxyapi -config /var/lib/cliproxyapi/config.yaml --antigravity-login --no-browser
{ config, ... }:
{
  services.cliproxyapi = {
    enable = true;
    # Bind localhost only; Tailscale HTTPS (:8317 -> 127.0.0.1:8317) is served
    # by `custom.t3code.tailscaleServe.extraProxies` in home/astroreen/hercules/home.nix.
    openFirewall = false;

    settings = {
      config-version = 8;

      server = {
        host = "127.0.0.1";
        port = 8317;
        trusted-proxies = [
          "127.0.0.1"
          "::1"
        ];
      };

      access.api-keys = [
        { _secret = "/var/lib/secrets/cliproxyapi-api-key"; }
      ];

      management = {
        # Allow management API + Web UI over Tailscale (still requires secret-key).
        allow-remote = true;
        secret-key._secret = "/var/lib/secrets/cliproxyapi-management-key";
        disable-control-panel = false;
      };

      routing = {
        strategy = "round-robin";
        # Pin each conversation (and its subagents) to one upstream credential
        # to preserve prompt cache hit rate; fail over automatically on quota/auth errors.
        session-affinity = true;
        session-affinity-ttl = "1h";
        session-affinity-subagents = true;
        retry = {
          request-retry = 3;
          max-retry-interval = 30;
        };
      };

      oauth.providers.antigravity.antigravity-credits = true;
    };
  };

  # Expose `cliproxyapi` on PATH for CLI OAuth logins (`sudo -u cliproxyapi ...`).
  environment.systemPackages = [ config.services.cliproxyapi.package ];
}
