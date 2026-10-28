{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./binds.nix # Dux keybinds (custom.keybinds)
  ];

  config = lib.mkIf config.custom.dux.enable {
    # Same quickshell build as caelestia: shares our nixpkgs Qt6, so the
    # shell and its QML plugins link against one Qt6 minor version.
    custom.dux.quickshellPackage =
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Additional packages to support dux shell
    home.packages = with pkgs; [
      papirus-icon-theme # Icons
      kdePackages.qt6ct # Qt6 configuration tool (QT_QPA_PLATFORMTHEME=qt6ct is set system-wide)
    ];
  };
}
