{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # Vivaldi Browser
      vivaldi
      vivaldi-ffmpeg-codecs
    ];

    sessionVariables = {
      CHROME_EXECUTABLE = "${pkgs.vivaldi}/bin/vivaldi";
    };
  };
}
