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

  # `gestures` is not a top-level hl.* function - HM's naive key->function
  # mapping tried to call `hl.gestures({...})`, which doesn't exist ->
  # "attempt to call a nil value (field 'gestures')". Like general/decoration/
  # dwindle/misc/animations in settings/default.nix, workspace-swipe options
  # live under `config` and get folded into the single hl.config({...}) call.
  config = {
    gestures = {
      workspace_swipe_distance = 300;
      workspace_swipe_invert = true;
      workspace_swipe_cancel_ratio = 0.5;
      workspace_swipe_create_new = true; # Create new workspace when swiping beyond the last workspace
      workspace_swipe_forever = false;
    };
  };

  # Same class of bug as `monitor` above: hl.gesture() needs a real Lua
  # table, not the old hyprlang comma-string. A raw string like
  # "4, horizontal, workspace" gets transliterated verbatim into
  # `hl.gesture("4, horizontal, workspace")`, which is a Lua string, not
  # a table - hence "hl.gesture: expected a table" at runtime.
  # Schema per https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/ :
  #   fingers (int), direction (string), action (string),
  #   optional: mods, scale, workspace_name, disable_inhibit.
  gesture = [
    {
      fingers = 4;
      direction = "horizontal";
      action = "workspace";
    }
    {
      fingers = 4;
      direction = "vertical";
      action = "special";
      workspace_name = "special";
    }
    {
      fingers = 3;
      direction = "swipe";
      action = "move";
    }
    {
      fingers = 3;
      direction = "pinch";
      action = "resize";
    }
  ];
}
