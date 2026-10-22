# Workstation layer on top of ../base: graphical session, audio, GUI apps.
_: {
  imports = [
    ./nix-ld.nix
    ./packages.nix
    ./network.nix
    ./services.nix
    ./display-manager.nix
    ./graphics.nix
    ./audio.nix
    ./fonts.nix
    ./printing.nix

    # Graphical apps (GUI)
    ../../profiles/apps/steam.nix # Steam configuration
    ../../profiles/apps/nautilus.nix # Nautilus configuration
    ../../profiles/apps/wireshark.nix # Wireshark configuration

    # Terminal related apps (tui)
    ../../profiles/terminal/openvpn # Open VPN configuration
    ../../profiles/terminal/shell/kitty.nix # Kitty terminal emulator

    # Languages
    ../../profiles/lang/flutter.nix # Flutter configuration
  ];
}
