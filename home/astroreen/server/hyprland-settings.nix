{ lib, ... }:
let
  # hl.exec_once does not exist in the real Lua API; official pattern is
  # hl.on("hyprland.start", function() hl.exec_cmd(cmd) end).
  mkStartup = cmd: {
    _args = [
      "hyprland.start"
      (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"${cmd}\")\nend")
    ];
  };
in
{
  # hl.workspace does not exist in the real Lua API; workspace->monitor
  # assignment is done via hl.workspace_rule({ workspace = ..., monitor = ... })
  workspace_rule = [
    {
      workspace = "1";
      monitor = "DP-3";
    } # Main
    {
      workspace = "2";
      monitor = "DP-3";
    } # Browser
    {
      workspace = "3";
      monitor = "DP-2";
    } # Discord
    {
      workspace = "4";
      monitor = "HDMI-A-1";
    } # Music
    {
      workspace = "5";
      monitor = "DP-3";
    } # Obsidian

    # Any other workspace will be created in the focused monitor
    # (where is the mouse, there will be created a new workspace)
  ];

  monitor = [
    {
      output = "DP-3";
      mode = "3440x1440@165";
      position = "0x0";
      scale = "1";
    }
    {
      output = "DP-2";
      mode = "1920x1080@60";
      position = "3440x-480";
      scale = "1";
      transform = 3;
    }
    {
      output = "HDMI-A-1";
      mode = "1920x1080@240";
      position = "-1080x-480";
      scale = "1";
      transform = 1;
    }
  ];

  # Startup commands — each element → hl.on("hyprland.start", function() ... end)
  on = map mkStartup [
    # Move mouse to main monitor
    "hyprctl dispatch workspace 1"

    # Set primary monitor
    "/home/astroreen/.local/share/nixos/scripts/restart-side-monitors.sh"
  ];
}
