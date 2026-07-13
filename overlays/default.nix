_: {
  nixpkgs.overlays = [
    (self: super: {
      spotx = import ./spotx.nix self super;
    })

    (_final: prev: {
      flutter = prev.flutter.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          # Fix: missing engine.realm in nixpkgs 3.41.6
          touch $out/bin/cache/engine.realm
        '';
      });
    })

  ];
}
