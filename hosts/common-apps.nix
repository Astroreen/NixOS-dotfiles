_: {
  imports = [
    # Graphical apps (GUI)
    ./modules/gui/steam.nix # Steam configuration
    ./modules/gui/nautilus.nix # Nautilus configuration
    ./modules/gui/wireshark.nix # Wireshark configuration
    ./modules/gui/gns3.nix # GNS3 configuration

    # Terminal apps (TUI)
    ./modules/tui/openvpn # Open VPN configuration
    ./modules/tui/shell # Shell settings
    ./modules/tui/tailscale.nix # Tailscale CLI configuration

    # Languages
    ./modules/lang/flutter
  ];
}
