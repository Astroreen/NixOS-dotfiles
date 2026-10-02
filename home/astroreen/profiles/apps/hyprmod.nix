# HyprMod — GTK4/libadwaita settings app for Hyprland.
#
# HyprMod writes its settings to a separate, mutable file
# (~/.config/hypr/hyprland-gui.lua) and expects the main Hyprland config to
# `require` it. We add that include declaratively via `extraConfig`, which
# home-manager appends LAST in the generated Lua — so HyprMod's settings
# override same-named options from the declarative base (e.g. monitors).
#
# Why the include is added here instead of letting HyprMod's first-run setup
# do it: home-manager generates ~/.config/hypr/hyprland.lua as a read-only
# symlink into the nix store. HyprMod's setup rewrites that file with
# `os.replace()`, which would silently replace the symlink with a regular
# file and break the next `home switch`. Pre-seeding the include makes
# HyprMod's `needs_setup()` return false, so it never touches the symlink.
{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  hyprmod = inputs.hyprmod.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ hyprmod ];

  # Since require is written, the HyprMod needs_setup() checks for this include
  # and if it isn't there, it will try to write it, which will not only fail,
  # because the config is read-only, but also it will delete the read-only symlink
  # and replace it with a regular file using `atomic_write -> os.replace()`, 
  # which will break the next home-manager switch. So we pre-seed the include to avoid this.
  wayland.windowManager.hyprland.extraConfig = ''
    -- HyprMod managed settings
    require("hyprland-gui")
  '';

  # `require("hyprland-gui")` errors if the module is missing, so ensure the
  # file exists before Hyprland starts. `touch` (not overwrite) preserves
  # whatever HyprMod has written across rebuilds.
  home.activation.hyprmodManagedFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    managed="${config.home.homeDirectory}/.config/hypr/hyprland-gui.lua"
    if [ ! -e "$managed" ]; then
      run mkdir -p "$(dirname "$managed")"
      run touch "$managed"
    fi
  '';
}
