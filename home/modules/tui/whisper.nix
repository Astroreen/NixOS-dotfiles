{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (whisper-cpp.override {
      cudaSupport = true;
      withFFmpegSupport = true; # for converting audio
    })
  ];
}
