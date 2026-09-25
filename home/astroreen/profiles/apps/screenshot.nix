{ pkgs, ... }:
let
  swappyShim = pkgs.callPackage ../../../package/gui/swappy-shim.nix { };
in
{
  # Satty - screenshot annotation tool + fake `swappy` shim (the shim
  # itself lives in home/package/gui/swappy-shim.nix). The caelestia
  # package overrides that feed the shim live in
  # home/astroreen/profiles/wm/hyprland/caelestia/default.nix (that is
  # where further caelestia shell/package overrides belong too).
  home.packages = with pkgs; [
    satty # Screenshot annotation tool (text, arrows, palette, blur)
    swappyShim # Fake `swappy` -> satty
  ];

  # Satty theme: gruvbox dark. Behavior flags (early-exit, copy-command,
  # save-after-copy, output-filename, actions-on-enter) live in the swappy
  # shim and override anything set in [general] here.
  xdg.configFile."satty/config.toml".text = ''
    [color-palette]
    # Quick-select palette (keys 1-9) - gruvbox dark brights
    palette = [
      "#fb4934ff", # red
      "#fe8019ff", # orange
      "#fabd2fff", # yellow
      "#b8bb26ff", # green
      "#8ec07cff", # aqua
      "#83a598ff", # blue
      "#d3869bff", # purple
      "#ebdbb2ff", # fg
      "#928374ff", # gray
    ]
    # Color picker presets - gruvbox dark darks
    custom = [
      "#cc241dff", # dark red
      "#d65d0eff", # dark orange
      "#d79921ff", # dark yellow
      "#98971aff", # dark green
      "#689d6aff", # dark aqua
      "#458588ff", # dark blue
      "#b16286ff", # dark purple
      "#282828ff", # bg
      "#3c3836ff", # bg1
    ]
  '';

  xdg.configFile."satty/overrides.css".text = ''
    /* Gruvbox dark for satty - loaded after builtin CSS */
    @define-color headerbar_bg_color #3c3836;
    @define-color headerbar_fg_color #ebdbb2;
    @define-color window_bg_color #282828;
    @define-color window_fg_color #ebdbb2;
    @define-color view_bg_color #32302f;
    @define-color view_fg_color #ebdbb2;
    @define-color accent_bg_color #d65d0e;
    @define-color accent_fg_color #fbf1c7;

    window, .root, .inner_box, .outer_box {
      background-color: #282828;
      color: #ebdbb2;
    }

    .toolbar {
      background-color: #3c3836;
      color: #ebdbb2;
    }

    button {
      background-color: #504945;
      color: #ebdbb2;
      border-color: #665c54;
    }

    button:hover {
      background-color: #665c54;
    }

    button:checked,
    button:active {
      background-color: #d65d0e;
      color: #fbf1c7;
    }

    entry {
      background-color: #32302f;
      color: #ebdbb2;
      border-color: #665c54;
    }
  '';

  # Keep satty floating and centered at the size the user runs it with
  # (live geometry from hyprctl clients: 1600x850). NOTE: `center` has
  # broken math on transformed (rotated) monitors on this host - see the
  # flutter.nix emulator rule for the explicit-move workaround if satty
  # ever lands off-screen.
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "^(com.gabm.satty)$";
      float = true;
      center = true;
      size = "1600 850";
    }
  ];
}
