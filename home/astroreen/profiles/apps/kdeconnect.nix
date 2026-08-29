{ pkgs, ... }:
{
  services.kdeconnect = {
    enable = true;
    indicator = true;
    # nautilus-python extension shipped by this package adds ~1.1s to nautilus
    # startup (heavy `import asyncio` cascade in kdeconnect-share.py, no
    # bytecode cache reuse observed via strace). Daemon itself is unaffected.
    package = pkgs.kdePackages.kdeconnect-kde.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        rm -rf $out/share/nautilus-python
      '';
    });
  };

  wayland.windowManager.hyprland.settings.window_rule = [
    # KDE Connect daemon window
    {
      match.class = "^(org.kde.kdeconnect.daemon)$";
      fullscreen_state = "0 3";
      size = "100% 100%";
      center = true;
      no_blur = true;
      no_anim = true;
      no_dim = true;
      no_focus = true;
      no_shadow = true;
      no_follow_mouse = true;
      rounding = 0;
      border_size = 0;
    }
  ];
}
