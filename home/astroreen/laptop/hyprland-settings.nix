{
  # hl.monitor() takes a dispatcher-style object, not a raw hyprlang
  # comma-separated string - passing the whole legacy "name,mode,pos,scale"
  # string as one argument produced `hl.monitor("eDP-1,1920x1080@165,0x0,1")`
  # in the generated Lua, which either throws (indexing a string like a
  # table) or silently no-ops under the Lua provider, the same class of bug
  # as the old `hyprctl dispatch <string>` syntax being invalid post-Lua-
  # migration (see home/astroreen/server/hyprland-settings.nix comments).
  monitor = [
    {
      output = "eDP-1";
      mode = "1920x1080@165";
      position = "0x0";
      scale = "1";
    }
  ];

  gestures = {
    workspace_swipe_distance = 300;
    workspace_swipe_invert = true;
    workspace_swipe_cancel_ratio = 0.5;
    workspace_swipe_create_new = true; # Create new workspace when swiping beyond the last workspace
    workspace_swipe_forever = false;
  };

  gesture = [
    "4, horizontal, workspace"
    "4, vertical, special, special"
    "3, swipe, move"
    "3, pinch, resize"
  ];
}
