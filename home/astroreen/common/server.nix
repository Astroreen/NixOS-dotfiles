# Headless home for server hosts, on top of ./base.nix.
_: {
  imports = [
    ./base.nix # Shell, devenv, opencode, claude-code, languages
    ../profiles/apps/t3code # T3 Code settings sync
  ];

  # `t3 serve` on 0.0.0.0:3773; the firewall keeps it tailnet-only.
  custom.t3code.service.enable = true;
}
