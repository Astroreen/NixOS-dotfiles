{
  monitor = [
    "eDP-1,1920x1080@165,0x0,1"
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
