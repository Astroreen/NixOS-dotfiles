{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    uv

    (python3.withPackages (
      ps: with ps; [
        pip
        aubio-ledfx
        numpy
        pyaudio
        inotify
        tkinter
      ]
    ))
  ];

  home.sessionVariables.LD_LIBRARY_PATH = "${
    lib.makeLibraryPath (
      with pkgs;
      [
        zlib
        openssl
      ]
    )
  }:$LD_LIBRARY_PATH";
}
