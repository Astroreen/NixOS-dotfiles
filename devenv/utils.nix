# Misc utilities: config sync helpers, disk inspection.
{ ... }:
{
  scripts = {
    sync-caelestia-config = {
      description = "Merge official caelestia-shell example config into host JSONs without overwriting set values";
      exec = "python3 scripts/sync-caelestia-config.py $@";
    };

    sync-dux-config = {
      description = "Copy the live Dux settings (~/.config/dms/settings.json) into home/astroreen/<host>/assets/dux-settings.json";
      exec = ''
        HOST="''${1:-$(hostname -s)}"
        SRC="''${XDG_CONFIG_HOME:-$HOME/.config}/dms/settings.json"
        DIR="''${DEVENV_ROOT:-.}/home/astroreen/$HOST"
        DST="$DIR/assets/dux-settings.json"

        if [ ! -d "$DIR" ]; then
          echo "❌ Unknown host '$HOST' (no $DIR)"
          exit 1
        fi
        if [ ! -s "$SRC" ]; then
          echo "❌ $SRC does not exist; is Dux running on this host?"
          exit 1
        fi

        # Validate + normalize (2-space indent, like dux itself writes it)
        jq --indent 2 . "$SRC" > "$DST.tmp" && mv "$DST.tmp" "$DST"
        echo "✅ $SRC -> $DST"
        git -C "''${DEVENV_ROOT:-.}" diff --stat -- "$DST"
      '';
    };

    sync-t3code-config = {
      description = "Fetch T3 Code settings/keybindings from live userdata into the repo (drops host-specific and secret keys)";
      exec = "python3 scripts/sync-t3code-config.py $@";
    };

    find-large-files.exec = ''
      COUNT="''${1:-30}"        # how much files to search for (default: 30)
      SEARCH_DIR="''${2:-/}"    # from where to search (default: entire disk)

      EXCLUDE_DIRS=(
        /proc
        /sys
        /dev
        /run
        /nix/store
        /mnt
      )

      # Строим аргументы -prune для find
      PRUNE_ARGS=()
      for dir in "''${EXCLUDE_DIRS[@]}"; do
        PRUNE_ARGS+=(-path "$dir" -prune -o)
      done

      echo "🔍 Searching for top-$COUNT files in $SEARCH_DIR ..."
      echo "   (excluded: ''${EXCLUDE_DIRS[*]})"
      echo ""

      find "$SEARCH_DIR" \
        "''${PRUNE_ARGS[@]}" \
        -type f -printf '%s\t%p\n' 2>/dev/null \
        | sort -rn \
        | head -n "$COUNT" \
        | awk '
          function human(bytes) {
            if (bytes >= 1073741824) return sprintf("%.1f GB", bytes/1073741824)
            if (bytes >= 1048576)    return sprintf("%.1f MB", bytes/1048576)
            if (bytes >= 1024)       return sprintf("%.1f KB", bytes/1024)
            return bytes " B"
          }
          { printf "%-10s %s\n", human($1), $2 }
        '
    '';
  };
}
