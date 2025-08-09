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

    hyprland.settings = # Not overriding but merging 
        import ../astroreen-common/hyprland/settings.nix //
        import ./hyprland-settings.nix;
}
