{ config, lib, ... }:
let
  cfg = config.custom.keybinds;

  # Which of the mutually exclusive actions a bind sets.
  actionsOf =
    bind:
    lib.filter (action: action != null) [
      bind.exec
      bind.global
      bind.hyprland.dispatch
    ];

  # Hyprland backend: one bind -> one hl.bind(keys, dispatcher, opts?) entry.
  toHyprland =
    bind:
    let
      lua = lib.generators.mkLuaInline;
      dispatcher =
        if bind.exec != null then
          # Lua long string, so the command may contain any quotes.
          lua "hl.dsp.exec_cmd([[${bind.exec}]])"
        else if bind.global != null then
          lua "hl.dsp.global(\"${bind.global}\")"
        else
          lua bind.hyprland.dispatch;
      flags =
        lib.filterAttrs (_: enabled: enabled) { inherit (bind) locked repeating; } // bind.hyprland.flags;
    in
    {
      _args = [
        bind.key
        dispatcher
      ]
      ++ lib.optional (flags != { }) flags;
    };
in
{
  options = with lib; {
    custom.keybinds.binds = mkOption {
      default = { };
      description = ''
        Window-manager-agnostic keybinds, keyed by name so a host can override
        or disable a single bind (`custom.keybinds.binds.<name>.enable = false`).
        Each bind sets exactly one action: `exec`, `global` or `hyprland.dispatch`.
        Backends translate the binds for the window manager in use; a backend
        skips actions it cannot express. Implemented backends: Hyprland.
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to bind this key.";
            };
            key = mkOption {
              type = types.str;
              example = "SUPER + SHIFT + Q";
              description = ''Modifiers and key joined with " + " (Hyprland key names).'';
            };
            exec = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Shell command to run. Portable across window managers.";
            };
            global = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "caelestia:launcher";
              description = "XDG global shortcut to trigger, as `<app id>:<shortcut id>`.";
            };
            locked = mkOption {
              type = types.bool;
              default = false;
              description = "Also works while the session is locked.";
            };
            repeating = mkOption {
              type = types.bool;
              default = false;
              description = "Repeats while the key is held.";
            };
            hyprland = {
              dispatch = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "hl.dsp.workspace.toggle_special()";
                description = "Raw Hyprland Lua dispatcher. Hyprland only.";
              };
              flags = mkOption {
                type = types.attrsOf types.bool;
                default = { };
                example = {
                  ignore_mods = true;
                };
                description = "Extra hl.bind options, merged over `locked`/`repeating`. Hyprland only.";
              };
            };
          };
        }
      );
    };
  };

  config =
    let
      enabledBinds = lib.filterAttrs (_: bind: bind.enable) cfg.binds;
    in
    {
      assertions = lib.mapAttrsToList (name: bind: {
        assertion = lib.length (actionsOf bind) == 1;
        message = "custom.keybinds.binds.${name} must set exactly one of exec, global or hyprland.dispatch";
      }) enabledBinds;

      wayland.windowManager.hyprland.settings = lib.mkIf config.wayland.windowManager.hyprland.enable {
        bind = map toHyprland (lib.attrValues enabledBinds);
      };
    };
}
