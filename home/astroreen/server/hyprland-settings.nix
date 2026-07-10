{ lib, ... }:
let
  # hl.dispatch() takes a dispatcher object (hl.dsp.*), not a raw hyprctl
  # string. `hyprctl dispatch <str>` is broken under the Lua provider because
  # hyprctl wraps the CLI arg literally into hl.dispatch(<arg>), which only
  # accepts valid Lua expressions (e.g. hl.dsp.focus({...})) - not
  # space-separated dispatcher syntax like "workspace 1". Call hl.dispatch
  # directly instead of shelling out to hyprctl.
  mkDispatch = luaExpr: {
    _args = [
      "hyprland.start"
      (lib.generators.mkLuaInline "function()\n  hl.dispatch(${luaExpr})\nend")
    ];
  };
in
{
  # hl.workspace does not exist in the real Lua API; workspace->monitor
  # assignment is done via hl.workspace_rule({ workspace = ..., monitor = ... })
  workspace_rule = [
    {
      workspace = "1";
      monitor = "DP-3";
    } # Main
    {
      workspace = "2";
      monitor = "DP-3";
    } # Browser
    {
      workspace = "3";
      monitor = "DP-2";
    } # Discord
    {
      workspace = "4";
      monitor = "HDMI-A-1";
    } # Music
    {
      workspace = "5";
      monitor = "DP-3";
    } # Obsidian

    # Any other workspace will be created in the focused monitor
    # (where is the mouse, there will be created a new workspace)
  ];

  # Polkit/keyring auth dialogs used to inherit the focused monitor from the
  # old hyprctl-dispatch startup flow; the new mkDispatch-only focus dispatch
  # doesn't control where independently-spawned agent windows land, so pin
  # the one recurring offender (gnome-keyring's prompt) explicitly instead
  # of writing rules for every app. The float+center part of this rule now
  # lives in home/astroreen/common/hyprland/settings.nix (every host has
  # this window); this is just the server-specific multi-monitor pin on
  # top of it - Hyprland applies all matching window_rule entries for a
  # class cumulatively, so this ADDS to the common rule, not replaces it.
  #
  # `monitor = "DP-3"` alone is NOT enough: confirmed via Hyprland source
  # (CWindow::onMap / setStaticProps in Window.cpp) that a window's initial
  # `m_monitor` from a window_rule's monitor effect gets UNCONDITIONALLY
  # overwritten afterwards by workspace-rule resolution
  # (`m_monitor = pWorkspace->m_monitor`) once the window's requested/
  # inherited workspace is resolved. Since this config's workspace_rule
  # maps ws3->DP-2 and ws4->HDMI-A-1, a dialog spawned while one of those
  # workspaces is focused would have its monitor rule silently discarded.
  # Force the workspace explicitly to one that workspace_rule already
  # pins to DP-3 (not "silent" - we want focus to actually jump there, the
  # same intent the old `hyprctl dispatch workspace 1` startup command
  # served before the Lua migration), so the two rule systems agree
  # instead of racing.
  window_rule = [
    {
      match.class = "^(gcr-prompter)$";
      monitor = "DP-3";
      workspace = "1";
    }
  ];

  monitor = [
    {
      output = "DP-3";
      mode = "3440x1440@165";
      position = "0x0";
      scale = "1";
    }
    {
      output = "DP-2";
      mode = "1920x1080@60";
      position = "3440x-480";
      scale = "1";
      transform = 3;
    }
    {
      output = "HDMI-A-1";
      mode = "1920x1080@60";
      position = "-1080x-480";
      scale = "1";
      transform = 1;
    }
  ];

  # Startup commands — each element → hl.on("hyprland.start", function() ... end)
  #
  # The old disable/re-enable toggle of the side monitors (scripts/
  # restart-side-monitors.sh) was a workaround for Hyprland having no
  # "primary monitor" concept (confirmed via source: no such field exists,
  # only "focused" does) - forcing DP-3 to be the last-focused monitor at
  # login so new apps (games, etc.) spawn there by default instead of a
  # side monitor. REMOVED: this toggle destroys and recreates the side
  # monitors' wl_output Wayland globals right at session start, which races
  # with XWayland's own startup - if XWayland binds to a wl_output that the
  # toggle then destroys, it crashes immediately and never recovers
  # (confirmed via journalctl: "XWAYLAND: wl_registry#2: error 0: global
  # wl_output (71) is unavailable"), permanently breaking any X11-only app
  # for the whole session (Android emulator, anything without a Wayland
  # platform plugin).
  #
  # The `mkDispatch focus DP-3` below already achieves the same "DP-3 is
  # the default/focused monitor at login" goal directly, without touching
  # monitor hardware state at all - and the per-app workspace_rule/
  # window_rule entries elsewhere in this repo (vesktop→DP-2, music→
  # HDMI-A-1) already handle the "except these two apps" exceptions.
  on = [
    (mkDispatch "hl.dsp.focus({ monitor = \"DP-3\" })")
  ];
}
