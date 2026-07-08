{ pkgs, ... }: {
  home.packages = with pkgs; [
    arduino-core
    arduino-ci
    arduino-cli
    arduino-ide
  ];
}
