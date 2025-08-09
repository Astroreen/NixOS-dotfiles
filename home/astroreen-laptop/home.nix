{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}: 
{
    imports = [
        ../astroreen-common/home.nix    # All the common settings
    ];

    # Host specific settings
    hyprland.settings = import ./hyprland-settings.nix;
}
