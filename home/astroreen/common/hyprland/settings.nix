_:
{
  # Keyboard and input — goes inside hl.config({...})
  config.input = {
    kb_layout = "us,ru,lt";
    kb_variant = ",phonetic,";
    kb_options = ""; # Layout switching handled by Hyprland binds (SHIFT+ALT+E/R/L)

    follow_mouse = 1;

    touchpad = {
      natural_scroll = true;
    };

    sensitivity = 0;
  };

  # Window rules — each element → hl.window_rule({...})
  window_rule = [
    # Modal windows float
    { match.modal = true; float = true; }
    # My own apps float during development
    { match.class = "me.astroreen"; float = true; }
    # Windows without a class float (e.g. vivaldi notifications)
    { match.class = "^(\\s*)$"; float = true; }

    # App-specific rules
    { match.class = "^(com.interversehq.qView)$"; size = "1400 800"; center = true; float = true; content = "photo"; }
    { match.class = "^(xdg-desktop-portal-gtk)$"; size = "1400 800"; center = true; float = true; }
    { match.class = "^(localsend_app)$"; size = "400 580"; center = true; float = true; }
    { match.class = "^(Postman)$"; size = "1400 800"; center = true; float = true; }
    # gcr-prompter (GNOME keyring/credential prompt) - float + center on
    # whatever monitor it lands on. Present on every host. Multi-monitor
    # hosts additionally pin it to a specific monitor+workspace in their
    # own host-specific hyprland-settings.nix, since a single generic rule
    # can't know which output is "the right one" per host.
    { match.class = "^(gcr-prompter)$"; center = true; float = true; }

    # Content-based rules
    { match.content = 3; float = true; }      # Games float
    { match.content = 1; float = true; }      # Photos float
    { match.content = 2; fullscreen = true; } # Videos fullscreen
  ];

  # Env vars — each element → hl.env(key, value)
  env = [
    { _args = [ "QT_QPA_PLATFORMTHEME" "qt6ct" ]; }
    { _args = [ "QUICKSHELL_ENABLE_PORTAL" "1" ]; }
  ];
}
