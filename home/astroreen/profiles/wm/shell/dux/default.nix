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
    ./plugins # Reviewed, pinned dux plugins
  ];

  config = lib.mkIf config.custom.dux.enable {
    # Portable part of the dux config, shared by every host; each host adds
    # its machine-bound keys (monitors, power, devices) from
    # home/astroreen/<host>/assets/dux-*.json. Both are refreshed from a live
    # host with `sync-dux-config [host]` (scripts/sync-dux-config.py).
    custom.dux = {
      settings = lib.importJSON ./settings.json;
      session = lib.importJSON ./session.json;
      pluginSettings = lib.importJSON ./plugin-settings.json;
    };

    # Same quickshell build as caelestia: shares our nixpkgs Qt6, so the
    # shell and its QML plugins link against one Qt6 minor version.
    custom.dux.quickshellPackage =
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Additional packages to support dux shell
    home.packages = with pkgs; [
      papirus-icon-theme # Icons
      # Dux bundles its own Material Symbols Rounded, but Qt resolves the
      # filled/weighted icon variants through fontconfig by family name
      material-symbols
      kdePackages.qt6ct # Qt6 configuration tool (QT_QPA_PLATFORMTHEME=qt6ct is set system-wide)
    ];
  };
}
