_: {
  imports = [
    ./nix-ld.nix
    ./generic.nix
    ./user.nix
    ./language.nix
    ./services.nix
    ./network.nix
    ./display-manager.nix
    ./graphics.nix
    ./audio.nix
    ./fonts.nix
    ./certificates.nix
    ./printing.nix

    # Graphical apps (GUI)
    ../profiles/apps/steam.nix # Steam configuration
    ../profiles/apps/nautilus.nix # Nautilus configuration
    ../profiles/apps/wireshark.nix # Wireshark configuration

    # Terminal related apps (tui)
    ../profiles/terminal/openvpn # Open VPN configuration
    ../profiles/terminal/shell # Shell settings
    ../profiles/terminal/tailscale.nix # Tailscale CLI configuration
    ../profiles/terminal/ssh.nix # SSH server configuration

    # Languages
    ../profiles/lang/flutter.nix # Flutter configuration
  ];
}
