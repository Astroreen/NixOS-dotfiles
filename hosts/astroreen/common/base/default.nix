# Headless base shared by every host (desktop and server).
_: {
  imports = [
    ./nix-ld.nix
    ./generic.nix
    ./user.nix
    ./language.nix
    ./network.nix
    ./certificates.nix

    # Terminal related apps (tui)
    ../../profiles/terminal/shell # Shell settings
    ../../profiles/terminal/tailscale.nix # Tailscale CLI configuration
    ../../profiles/terminal/ssh.nix # SSH server configuration
  ];
}
