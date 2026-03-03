{ ... }:
{
  imports = [
    ./modules/gui/steam.nix # Steam configuration
    ./modules/gui/nautilus.nix # Nautilus configuration
    ./modules/gui/wireshark.nix # Wireshark configuration
    ./modules/gui/gns3.nix # GNS3 configuration

    ./modules/tui/openvpn # Open VPN configuration

    # Languages
    ./modules/lang/flutter
  ];
}
