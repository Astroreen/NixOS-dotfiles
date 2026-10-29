{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Fake `swappy` -> satty, see home/package/apps/swappy-shim.nix for the
  # shim itself (callPackage style, like unmined.nix).
  swappyShim = pkgs.callPackage ../../../../../package/apps/swappy-shim.nix { };

  # The caelestia shell/cli packages bake their dependency paths into the
  # package wrappers (makeWrapper --prefix PATH), which SHADOWS anything
  # from home.packages - that is why a plain shim in home.packages was
  # invisible to the caelestia service. Re-point the `swappy` dependency
  # of both packages at the shim so the QML picker and the CLI (including
  # the cli nested in the shell's own wrapper PATH) launch satty.
  caelestiaCliPkg = inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default.override {
    swappy = swappyShim;
  };
  caelestiaShellPkg = inputs.caelestia-shell.packages.${system}.with-cli.override {
    swappy = swappyShim;
    caelestia-cli = caelestiaCliPkg;
  };
in
{
  imports = [
    ./binds.nix # Caelestia keybinds (custom.keybinds)
  ];

  config = lib.mkIf config.custom.caelestia.enable {
    custom.caelestia = {
      # Same NVENC/FFmpeg fix as programs.gpu-screen-recorder in
      # hosts/astroreen/profiles/wm/hyprland
      recorderPackage = lib.mkDefault (pkgs.gpu-screen-recorder.override { ffmpeg = pkgs.ffmpeg_8; });
      package = caelestiaShellPkg;
      cliPackage = caelestiaCliPkg;
      environment = [
        "QT_QPA_PLATFORM=wayland"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "QUICKSHELL_ENABLE_PORTAL=1"
        "XDG_SESSION_TYPE=wayland"
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_DESKTOP=Hyprland"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "WAYLAND_DISPLAY=wayland-1"
      ];
      # Pinned over the host's shell.json (its paths point at bundled assets)
      settingsOverrides.paths = {
        mediaGif = ../../../../common/assets/kirby-groove.gif;
        sessionGif = ../../../../common/assets/evernight-dance.gif;
      };
    };

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
      imagemagick # Image manipulation tool
      safeeyes # Eye protection tool

      # Might be the wrong packages
      gdbuspp
      libpulseaudio
      rubyPackages_3_4.glib2
      gcc
    ];
  };
}
