{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.caelestia = {
    enable = true;
    systemd = {
      enable = true;
      target = "graphical-session.target";
      environment = [
        "QT_QPA_PLATFORM=wayland"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "QUICKSHELL_ENABLE_PORTAL=1"
      ];
    };
    settings = { };
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = { };
    };
  };

  # systemd.user.services.caelestia = {
  #   Unit = {
  #     Description = "Caelestia desktop shell";
  #     After = [ "graphical-session.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Service = {
  #     Type = "exec";
  #     ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
  #     ExecStart = "${inputs.caelestia-shell.packages.${pkgs.system}.with-cli}/bin/caelestia-shell";

  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #     RestartPreventExitStatus = "0";
  #     RuntimeDirectory = "caelestia";
  #     RuntimeDirectoryMode = "0755";

  #     Slice = "app-graphical.slice";

  #     Environment = [
  #       "QT_QPA_PLATFORM=wayland"
  #       "QT_QPA_PLATFORMTHEME=qt6ct"
  #       "QUICKSHELL_ENABLE_PORTAL=1"
  #     ];
  #   };
  # };

  # Additional packages to support caelestia shell
  home.packages = with pkgs; [
    # Icons
    papirus-icon-theme
    material-symbols

    # Packages
    dart-sass # Sass compiler
    ydotool # Wayland input automation tool
    fuzzel # Fuzzy launcher
    slurp # Select a region on the screen
    fish # Fish shell
    cava # Audio visualizer
    aubio # Audio analysis library
    glibc # GNU C Library
    kdePackages.qt6ct # Qt6 configuration tool
    qt6.qtdeclarative # Qt6 declarative module
    libqalculate # Calculator library
    swappy # Image editor for screenshots
    ibm-plex # IBM Plex font
    imagemagick # Image manipulation tool
    safeeyes # Eye protection tool
    gpu-screen-recorder # Screen recorder that uses GPU for encoding

    # Python packages
    (python3.withPackages (
      ps: with ps; [
        aubio
        numpy
        pyaudio
        inotify
      ]
    ))

    # Might be the wrong packages
    gdbuspp
    libpulseaudio
    rubyPackages_3_4.glib2
    gcc
  ];
}
