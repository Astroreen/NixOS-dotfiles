# AnyDesk remote desktop
{ pkgs, pkgs-stable, ... }:
{
  home.packages = [
    # patchelf 0.19 (unstable) adds a LOAD segment that overlaps the next one,
    # so ld.so segfaults in dl_main on start; 0.15 from stable patches it cleanly.
    # The 8.1.0 tarball was also re-uploaded upstream, so its hash changed.
    (pkgs.anydesk.overrideAttrs (old: {
      src = pkgs.fetchurl {
        inherit (old.src) url;
        hash = "sha256-zS5P2eyTHZY7cBW8mQ2Q6M0lXcx9VZZTtpG3Bb6u7IQ=";
      };
      postFixup =
        builtins.replaceStrings [ "patchelf \\" ] [ "${pkgs-stable.patchelf}/bin/patchelf \\" ]
          old.postFixup;
    }))
  ];
}
