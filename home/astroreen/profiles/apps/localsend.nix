{ lib, ... }:
{
  imports = [ ../../../modules/apps/localsend.nix ];

  # Always-on receiver; port 53317 is opened in hosts/astroreen/common/desktop/network.nix.
  # Hosts that only want it on demand set `autostart = false`.
  custom.localsend = {
    enable = true;
    autostart = lib.mkDefault true;
  };

  # LocalSend 1.18 changed its Wayland app_id from `localsend_app` to
  # `org.localsend.localsend_app`; match both so the rule survives the rename.
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(org\\.localsend\\.)?localsend_app$";
      size = "400 580";
      center = true;
      float = true;
    }
  ];
}
