{ pkgs, lib }:
{
  # Activation that keeps a shell's JSON config writable (a real file, not a
  # store symlink) and merges declarative values into it:
  #   defaults   only fill keys the file does not have yet, so whatever the
  #              shell's settings UI saved survives a rebuild; with
  #              `overrideDefaults` they win over the file instead (keys only
  #              the file has are still kept)
  #   overrides  always win, for values that must track the nix config
  # Objects merge recursively; arrays are replaced whole. `service` is
  # restarted (only if running) when the merged content actually changed.
  mkJsonConfigActivation =
    {
      path,
      defaults ? { },
      overrideDefaults ? false,
      overrides ? { },
      service ? null,
      # Activation steps this one must follow
      after ? [ "writeBoundary" ],
    }:
    let
      jq = lib.getExe pkgs.jq;
      defaultsFile = pkgs.writeText "shell-defaults.json" (builtins.toJSON defaults);
      overridesFile = pkgs.writeText "shell-overrides.json" (builtins.toJSON overrides);
      emptyFile = pkgs.writeText "empty.json" "{}";
      # jq slurps [defaults, file, overrides]; `*` lets the right side win
      mergeExpr = if overrideDefaults then ".[1] * .[0] * .[2]" else ".[0] * .[1] * .[2]";
    in
    lib.hm.dag.entryAfter after ''
      CONF=${lib.escapeShellArg path}
      mkdir -p "$(dirname "$CONF")"

      CURRENT="$CONF"
      [ -s "$CONF" ] || CURRENT=${emptyFile}

      if MERGED=$(${jq} -s '${mergeExpr}' ${defaultsFile} "$CURRENT" ${overridesFile}); then
        # Compare canonical forms, so formatting differences alone don't rewrite the file
        if [ ! -s "$CONF" ] || [ "$(${jq} -cS . <<< "$MERGED")" != "$(${jq} -cS . "$CONF")" ]; then
          rm -f "$CONF" # drop a stale read-only store symlink, if any
          printf '%s\n' "$MERGED" > "$CONF"
          chmod 644 "$CONF"
          ${lib.optionalString (service != null) "systemctl --user try-restart ${service} || true"}
        fi
      else
        echo "warning: $CONF is not valid JSON, leaving it untouched" >&2
      fi
    '';
}
