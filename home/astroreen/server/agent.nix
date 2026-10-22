# Home Manager for the `agent` account on the server, applied through the
# NixOS home-manager module (see hosts/astroreen/server/configuration.nix).
_: {
  imports = [
    ../common/base.nix # Same shell + opencode/claude-code setup as astroreen
  ];

  home.stateVersion = "26.05";
}
