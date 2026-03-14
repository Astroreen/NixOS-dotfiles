{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uv
    
    # Python with packages
    (python3.withPackages (
      ps: with ps; [
        pip
        aubio
        numpy
        pyaudio
        inotify
      ]
    ))

  ];
}
