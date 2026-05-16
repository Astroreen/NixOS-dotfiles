{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.custom.binds;
in
{
  options = with lib; {
    custom.binds = {
      enable = mkEnableOption "Enable bind configuration for hyprland";
      global = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Global bind configuration for hyprland";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    wayland.windowManager.hyprland = {
      submaps = {
        global.settings = cfg.global;
      };
    };
  };
}
