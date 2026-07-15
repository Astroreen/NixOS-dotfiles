{ pkgs, lib, ... }:
{
  # Plain home-manager wayvnc module: single instance, default (first)
  # output, flat address/port config - this is what was in place before
  # the hyprlang->Lua migration and "worked flawlessly". Two known,
  # confirmed-upstream (not config-fixable) limitations to be aware of:
  #   - `wayvncctl output-cycle`/`output-set` doesn't actually switch the
  #     video stream (wayvnc 0.10.0: wayvnc_display->image_source is set
  #     once at creation in wayvnc_display_add and never reassigned;
  #     switch_to_output() only updates self->image_source, so
  #     on_capture_done()'s wayvnc_display_find_by_source() lookup stops
  #     matching after a switch and frames are silently dropped - input
  #     still follows correctly since that path reads self->image_source
  #     directly). No keybind for it below since it wouldn't do anything
  #     useful.
  #   - Pointer clicks are mismapped on any monitor with a non-zero
  #     Hyprland `transform` (see monitor = [...] in
  #     home/astroreen/server/hyprland-settings.nix - DP-2/HDMI-A-1):
  #     wayvnc only re-applies its (correct) rotation-compensation math
  #     when the active screencopy backend reports
  #     SCREENCOPY_CAP_TRANSFORM and the compositor sends a `transform`
  #     frame event; whichever of those isn't happening for this
  #     Hyprland/wayvnc pairing leaves the pointer uncompensated. Not
  #     reproducible on an untransformed output (confirmed: DP-3, the
  #     default/first output here, has correct clicks).
  services.wayvnc = {
    enable = true;
    autoStart = true;
    settings = {
      address = "0.0.0.0";
      port = 5900;
    };
  };

  home.packages = with pkgs; [
    tigervnc # VNC viewer
  ];

  wayland.windowManager.hyprland.settings = {
    # NOTE: F12 passthrough submap dropped during hyprlang->Lua migration
    # (wayvnc is disabled; re-add via hl.define_submap if VNC is re-enabled)
    bind = [
      {
        _args = [
          "CTRL + SUPER + SHIFT + semicolon"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wayvncctl output-cycle\")")
        ];
      } # Cycle wayvnc output across monitors
    ];

    window_rule = [
      # VNC viewer should float and be centered
      {
        match.class = "^(Vncviewer)$";
        float = true;
        center = true;
      }
    ];
  };
}
