# Home Manager for the `agent` account on server hosts, applied through the
# NixOS home-manager module (see hosts/astroreen/common/server/default.nix).
_: {
  imports = [
    ../common/base.nix # Same shell + opencode/claude-code setup as astroreen
  ];

  home.stateVersion = "26.05";
}
