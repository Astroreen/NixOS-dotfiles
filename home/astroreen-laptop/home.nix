{
  config,
  pkgs,
  inputs,
  lib,
  osConfig,
  ...
}:
let
  # Custom merge function for Hyprland settings
  mergeHyprlandSettings =
    base: custom:
    lib.recursiveUpdate base (
      custom
      // {
        # Special handling for lists that should be concatenated
        exec-once = (base.exec-once or [ ]) ++ (custom.exec-once or [ ]);
        env = (base.env or [ ]) ++ (custom.env or [ ]);
        monitor = (base.monitor or [ ]) ++ (custom.monitor or [ ]);
        workspace = (base.workspace or [ ]) ++ (custom.workspace or [ ]);
        windowrulev2 = (base.windowrulev2 or [ ]) ++ (custom.windowrulev2 or [ ]);
        bind = (base.bind or [ ]) ++ (custom.bind or [ ]);
        bindm = (base.bindm or [ ]) ++ (custom.bindm or [ ]);
        bindr = (base.bindr or [ ]) ++ (custom.bindr or [ ]);
        bindle = (base.bindle or [ ]) ++ (custom.bindle or [ ]);
        bindel = (base.bindel or [ ]) ++ (custom.bindel or [ ]);
      }
    );

  # Import the settings
  commonSettings = import ../astroreen-common/hyprland/settings.nix;
  hostSettings = import ./hyprland-settings.nix;
in
{
  imports = [
    ../astroreen-common/home.nix # All the common settings
  ];

  # Host specific settings - properly merged
  hyprland.settings = mergeHyprlandSettings commonSettings hostSettings;
}
