{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [
    (inputs.oskars-dotfiles.overlays.spotx) # SpotX
  ];
}
