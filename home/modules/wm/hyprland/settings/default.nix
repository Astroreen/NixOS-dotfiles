{ lib, pkgs, ... }:
let
  # hl.exec_once does not exist in the real Lua API (HM's naive key->function
  # mapping produces an invalid call); the official pattern is
  # hl.on("hyprland.start", function() hl.exec_cmd(cmd) end).
  mkStartup = cmd: {
    _args = [
      "hyprland.start"
      (lib.generators.mkLuaInline "function()\n  hl.exec_cmd(\"${cmd}\")\nend")
    ];
  };
in
{
  # Monitor fallback
  monitor = lib.mkDefault [ ", preferred, auto, 1" ];

  # Config options — generates hl.config({...})
  config = {
    general = {
      layout = "dwindle";
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      resize_on_border = true;
    };

    decoration = {
      rounding = 15;
      active_opacity = 1.0;
      inactive_opacity = 0.99;
      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
        vibrancy = 0.1696;
      };
    };

    dwindle = {
      preserve_split = true;
    };

    misc = {
      force_default_wallpaper = 0;
      disable_hyprland_logo = true;
      session_lock_xray = true;
    };

    animations.enabled = true;
  };

  # Bezier curves — each element → hl.curve(name, { type = "bezier", points = { {x0,y0}, {x1,y1} } })
  curve = lib.mkDefault [
    {
      _args = [
        "linear"
        {
          type = "bezier";
          points = [
            [ 0.0 0.0 ]
            [ 1.0 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "md3_standard"
        {
          type = "bezier";
          points = [
            [ 0.2 0.0 ]
            [ 0.0 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "md3_decel"
        {
          type = "bezier";
          points = [
            [ 0.05 0.7 ]
            [ 0.1 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "md3_accel"
        {
          type = "bezier";
          points = [
            [ 0.3 0.0 ]
            [ 0.8 0.15 ]
          ];
        }
      ];
    }
    {
      _args = [
        "overshot"
        {
          type = "bezier";
          points = [
            [ 0.05 0.9 ]
            [ 0.1 1.05 ]
          ];
        }
      ];
    }
    {
      _args = [
        "hyprnostretch"
        {
          type = "bezier";
          points = [
            [ 0.05 0.9 ]
            [ 0.1 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "win10"
        {
          type = "bezier";
          points = [
            [ 0.0 0.0 ]
            [ 0.0 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "gnome"
        {
          type = "bezier";
          points = [
            [ 0.0 0.85 ]
            [ 0.3 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "funky"
        {
          type = "bezier";
          points = [
            [ 0.46 0.35 ]
            [ (-0.2) 1.2 ]
          ];
        }
      ];
    }
    {
      _args = [
        "smoothIn"
        {
          type = "bezier";
          points = [
            [ 0.25 1.0 ]
            [ 0.5 1.0 ]
          ];
        }
      ];
    }
    {
      _args = [
        "holographic"
        {
          type = "bezier";
          points = [
            [ 0.6 0.04 ]
            [ 0.98 0.335 ]
          ];
        }
      ];
    }
  ];

  # Animation rules — each element → hl.animation({ leaf, enabled, speed, bezier, style? })
  animation = lib.mkDefault [
    {
      leaf = "border";
      enabled = true;
      speed = 3;
      bezier = "smoothIn";
    }
    {
      leaf = "borderangle";
      enabled = true;
      speed = 50;
      bezier = "linear";
      style = "once";
    }
    {
      leaf = "windows";
      enabled = true;
      speed = 3;
      bezier = "md3_standard";
      style = "popin";
    }
    {
      leaf = "fadeIn";
      enabled = true;
      speed = 2;
      bezier = "default";
    }
    {
      leaf = "fadeOut";
      enabled = true;
      speed = 3;
      bezier = "default";
    }
    {
      leaf = "workspaces";
      enabled = true;
      speed = 4;
      bezier = "md3_decel";
      style = "slide";
    }
    {
      leaf = "specialWorkspace";
      enabled = true;
      speed = 5;
      bezier = "overshot";
      style = "slidefadevert 50%";
    }
  ];

  # Startup commands — each element → hl.on("hyprland.start", function() ... end)
  on = map mkStartup [
    "power-profiles-daemon"
    "nm-applet --no-agent"
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user start graphical-session.target"
  ];

  # Env vars — each element → hl.env(key, value)
  env = [
    { _args = [ "NIXOS_OZONE_WL" "1" ]; }
    { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
    { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
    { _args = [ "XDG_DESKTOP_DIR" "$HOME/Desktop" ]; }
    { _args = [ "XDG_DOWNLOAD_DIR" "$HOME/Downloads" ]; }
    { _args = [ "XDG_TEMPLATES_DIR" "$HOME/Templates" ]; }
    { _args = [ "XDG_PUBLICSHARE_DIR" "$HOME/Public" ]; }
    { _args = [ "XDG_DOCUMENTS_DIR" "$HOME/Documents" ]; }
    { _args = [ "XDG_MUSIC_DIR" "$HOME/Music" ]; }
    { _args = [ "XDG_PICTURES_DIR" "$HOME/Pictures" ]; }
    { _args = [ "XDG_VIDEOS_DIR" "$HOME/Videos" ]; }
    { _args = [ "HYPRSHOT_DIR" "$HOME/Pictures/Screenshots" ]; }
    { _args = [ "WAYLAND_DISPLAY" "wayland-1" ]; }
  ];
}
