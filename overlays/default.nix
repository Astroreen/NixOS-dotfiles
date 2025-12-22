{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [ 
    (self: super: {
      spotx = import ./spotx.nix self super;
    })
  ];
}
