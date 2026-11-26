# Route astroreen's AI CLIs (Claude Code, Codex, OpenCode openai/google) through
# the CLIProxyAPI server on hercules (127.0.0.1:8317, exposed over Tailscale
# HTTPS via `tailscale serve` at https://hercules.bumblebee-parrotfish.ts.net:8317).
#
# Provision the client key once per host (mode 0600, never committed):
#   On hercules:
#     sudo install -D -m 600 -o astroreen -g users \
#       /var/lib/secrets/cliproxyapi-api-key ~/.config/cliproxyapi/api-key
#   On laptop / pc:
#     ssh hercules cat ~/.config/cliproxyapi/api-key \
#       | install -D -m 600 /dev/stdin ~/.config/cliproxyapi/api-key
#   Then run `home switch "$(hostname -s)"` to patch ~/.claude/settings.json and
#   ~/.codex/config.toml.
#
# T3 Code Usage Hub (Settings -> Providers -> Usage providers -> Add hub):
#   URL:            https://hercules.bumblebee-parrotfish.ts.net:8317
#   Management key: contents of /var/lib/secrets/cliproxyapi-management-key
{ host, lib, ... }:
{
  imports = [
    ../../../../modules/terminal/ai
  ];

  custom.ai.cliproxyapi = {
    enable = lib.mkDefault (
      builtins.elem host [
        "hercules"
        "laptop"
        "pc"
      ]
    );
    # Same Tailscale HTTPS URL on every host (including hercules) so Claude,
    # Codex and T3 Code's Usage Hub all match one canonical origin.
    baseUrl = "https://hercules.bumblebee-parrotfish.ts.net:8317";
  };
}
