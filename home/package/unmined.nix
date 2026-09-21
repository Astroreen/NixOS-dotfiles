{
  stdenv,
  buildFHSEnv,
  libICE,
  libSM,
  libX11,
  libXext,
  libXrandr,
  libXi,
  libXcursor,
  fontconfig,
  freetype,
  zlib,
  openssl,
  icu,
  lib,
  fetchurl,
  makeDesktopItem,
  ...
}:

let
  desktopItem = makeDesktopItem {
    name = "unmined-gui";
    exec = "unmined-gui";
    desktopName = "uNmINeD";
    comment = "Minecraft Map Viewer";
    categories = [ "Game" ];
  };

  unmined-unwrapped = stdenv.mkDerivation {
    pname = "unmined-gui";
    version = "0.19.60-dev";

    src = fetchurl {
      url = "https://unmined.net/download/unmined-gui-linux-x64-dev/";
      hash = "sha256-1MKC2vaYSFB2cGRa3S5OJEp1mxU2MyW3Foym2z60tg0=";
      name = "unmined-gui.tar.gz";
    };

    dontPatchELF = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out/lib/unmined
      cp -r . $out/lib/unmined/
    '';

    meta.description = "Minecraft map viewer";
  };
in

buildFHSEnv {
  name = "unmined-gui";
  targetPkgs =
    pkgs: with pkgs; [
      libICE
      libSM
      libX11
      libXext
      libXrandr
      libXi
      libXcursor
      fontconfig
      freetype
      zlib
      stdenv.cc.cc.lib
      openssl
      icu
    ];
  runScript = "${unmined-unwrapped}/lib/unmined/unmined";

  extraInstallCommands = ''
    cp -r ${desktopItem}/share $out/share
  '';

  meta = {
    description = "Minecraft map viewer (uNmINeD)";
    mainProgram = "unmined-gui";
  };
}
