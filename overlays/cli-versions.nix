# Share current CLI packages and their matching toolchains across NixOS,
# standalone Home Manager and T3 Code's wrapper PATH.
nixpkgs-cli: _final: prev:
let
  cliPkgs = import nixpkgs-cli { inherit (prev.stdenv.hostPlatform) system; };
in
{
  inherit (cliPkgs)
    cliproxyapi
    codex
    tailscale
    tailscale-nginx-auth
    ;
}
