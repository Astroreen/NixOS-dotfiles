{ pkgs, ... }:
{
  home.packages = with pkgs; [
    prismlauncher

    # Map Viewer - Unmined
    # (pkgs.callPackage ../../../package/unmined.nix { }) # Broken hash
  ];

  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "minecraft";
      center = true;
      float = true;
    }
  ];
}
