{ pkgs, lib }:
{
  # Activation that keeps a shell's JSON config writable (a real file, not a
  # store symlink) and merges declarative values into it:
  #   defaults   only fill keys the file does not have yet, so whatever the
  #              shell's settings UI saved survives a rebuild; with
  #              `overrideDefaults` they win over the file instead (keys only
  #              the file has are still kept)
  #   overrides  always win, for values that must track the nix config
  # Objects merge recursively; arrays are replaced whole. When the merged
  # content actually changed, a running `service` is stopped before the write
  # and started again after it: the shell may save its in-memory copy on exit,
  # which would otherwise overwrite the merge (the merge is redone on top of
  # whatever it saved).
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

      merge() {
        ${jq} -s '${mergeExpr}' ${defaultsFile} "$CURRENT" ${overridesFile}
      }

      if MERGED=$(merge); then
        # Compare canonical forms, so formatting differences alone don't rewrite the file
        if [ ! -s "$CONF" ] || [ "$(${jq} -cS . <<< "$MERGED")" != "$(${jq} -cS . "$CONF")" ]; then
          ${lib.optionalString (service != null) ''
            WAS_ACTIVE=
            if systemctl --user is-active --quiet ${service}; then
              WAS_ACTIVE=1
              systemctl --user stop ${service} || true
              [ -s "$CONF" ] && CURRENT="$CONF"
              MERGED=$(merge) || MERGED=
            fi
          ''}
          if [ -n "$MERGED" ]; then
            rm -f "$CONF" # drop a stale read-only store symlink, if any
            printf '%s\n' "$MERGED" > "$CONF"
            chmod 644 "$CONF"
          fi
          ${lib.optionalString (
            service != null
          ) ''[ -n "$WAS_ACTIVE" ] && systemctl --user start ${service} || true''}
        fi
      else
        echo "warning: $CONF is not valid JSON, leaving it untouched" >&2
      fi
    '';
}
