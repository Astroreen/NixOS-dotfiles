{
  pkgs,
  ...
}:

{
  imports = [
    ./devenv/nixos.nix # NixOS / Home Manager build & lifecycle
    ./devenv/work.nix # Work VPN / DNS
    ./devenv/utils.nix # Config sync helpers, disk inspection
  ];

  packages = with pkgs; [
    deadnix
    jq
    nixos-anywhere
    python3
    statix
  ];
}
