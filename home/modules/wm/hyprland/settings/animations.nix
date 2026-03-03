{
  enabled = true;

  bezier = [
    "linear, 0.0, 0.0, 1.0, 1.0"
    "md3_standard, 0.2, 0.0, 0, 1.0"
    "md3_decel, 0.05, 0.7, 0.1, 1"
    "md3_accel, 0.3, 0, 0.8, 0.15"
    "overshot, 0.05, 0.9, 0.1, 1.05"
    "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
    "win10, 0, 0, 0, 1"
    "gnome, 0, 0.85, 0.3, 1"
    "funky, 0.46, 0.35, -0.2, 1.2"
    "smoothIn, 0.25, 1.0, 0.5, 1.0"
    "holographic, 0.6, 0.04, 0.98, 0.335"
  ];

  animation = [
    "border, 1, 3, smoothIn"
    "borderangle, 1, 50, linear, once"
    "windows, 1, 3, md3_standard, popin"
    "fadeIn, 1, 2, default"
    "fadeOut, 1, 3, default"
    "workspaces, 1, 4, md3_decel, slide"
    "specialWorkspace, 1, 5, overshot, slidefadevert 50%"
  ];
}
