{ pkgs, ... }:

{
  programs.lutris = {
    enable = true;
    defaultWinePackage = pkgs.wineWow64Packages.waylandFull;
    winePackages = with pkgs; [
      winetricks
      wineWow64Packages.stagingFull
      wineWow64Packages.unstableFull
    ];
    extraPackages = with pkgs; [
      mangohud
      winetricks
      gamescope
      gamemode
      umu-launcher
    ];

    # Should be the same as package in steam.nix
    steamPackage = pkgs.steam;
  };

  # home.packages = [
  #   (pkgs.lutris.override {
  #     extraPkgs = pkgs: [
  #       winetricks
  #       wineWowPackages.waylandFull
  #       wineWowPackages.stagingFull
  #     ];

  #     steamPackage = pkgs.steam;
  #   })
  # ];
}
