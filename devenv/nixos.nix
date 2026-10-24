# NixOS / Home Manager build & lifecycle scripts.
{ ... }:
{
  env.CURRENT_USER = "astroreen";

  scripts = {
    nixos = {
      description = "Manage NixOS configuration (switch, test, boot, build, dry-build, dry-activate, rollback)";
      exec = ''
        ACTION="''${1:?Usage: nixos <action> <host>}"
        HOST="''${2:?Usage: nixos <action> <host>}"

        if [ "$ACTION" = "rollback" ]; then
          sudo nixos-rebuild switch --no-reexec --flake ".#$CURRENT_USER@$HOST" --rollback
        else
          git add .
          sudo nixos-rebuild "$ACTION" --no-reexec --flake ".#$CURRENT_USER@$HOST"
        fi
      '';
    };
    nx.exec = "nixos $@"; # Alias for nixos-rebuild

    home = {
      description = "Manage Home Manager configuration (switch, build, rollback)";
      exec = ''
        ACTION="''${1:?Usage: home <action> <host>}"
        HOST="''${2:?Usage: home <action> <host>}"

        if [ "$ACTION" = "rollback" ]; then
          home-manager switch --rollback --flake ".#$CURRENT_USER@$HOST"
        else
          git add .
          home-manager "$ACTION" --flake ".#$CURRENT_USER@$HOST"
        fi
      '';
    };
    hm.exec = "home $@"; # Alias for home manager

    deploy = {
      description = "Deploy NixOS + Home Manager to a remote host over SSH (switch, test, boot, dry-activate)";
      exec = ''
        ACTION="''${1:?Usage: deploy <action> <host>}"
        HOST="''${2:?Usage: deploy <action> <host>}"
        TARGET="$CURRENT_USER@$HOST"

        git add .
        # Built locally, copied and activated on the target.
        nixos-rebuild "$ACTION" --no-reexec --flake ".#$TARGET" --target-host "$TARGET" --elevate sudo

        if [ "$ACTION" = "switch" ]; then
          HM=$(nix build --no-link --print-out-paths ".#homeConfigurations.\"$TARGET\".activationPackage")
          nix copy --to "ssh://$TARGET" "$HM"
          ssh "$TARGET" "$HM/activate"
        fi
      '';
    };

    bootstrap = {
      description = "Install a host from scratch with nixos-anywhere (WIPES the target disk)";
      exec = ''
        HOST="''${1:?Usage: bootstrap <host> <root@ip> [tailscale-authkey-file]}"
        TARGET="''${2:?Usage: bootstrap <host> <root@ip> [tailscale-authkey-file]}"
        AUTHKEY="''${3:-}"
        HOST_DIR="hosts/$CURRENT_USER/$HOST"

        KEYS="hosts/$CURRENT_USER/common/server/authorized_keys"

        # Password login is disabled on the installed system: no key = locked out.
        if ! grep -qv '^[[:space:]]*\(#\|$\)' "$KEYS"; then
          echo "error: $KEYS has no public key" >&2
          exit 1
        fi

        EXTRA=$(mktemp -d)
        trap 'rm -rf "$EXTRA"' EXIT
        if [ -n "$AUTHKEY" ]; then
          install -D -m 600 "$AUTHKEY" "$EXTRA/var/lib/tailscale/authkey"
        fi

        git add .
        nixos-anywhere --flake ".#$CURRENT_USER@$HOST" \
          --generate-hardware-config nixos-generate-config "$HOST_DIR/hardware-configuration.nix" \
          --extra-files "$EXTRA" \
          "$TARGET"
      '';
    };

    update-flake = {
      exec = "nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes";
      description = "Update the Nix flake";
    };

    list-generations = {
      description = "List NixOS generations";
      exec = "nixos-rebuild list-generations";
    };

    delete-generations = {
      description = "Delete old NixOS generations";
      exec = ''
        # How many generations to keep (default: 5)
        KEEP_COUNT="''${1:-5}"
        echo "Deleting old NixOS generations, keeping the last $KEEP_COUNT generations..."
        sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +$KEEP_COUNT
      '';
    };

    delete-garbage = {
      exec = ''
        nix-collect-garbage --delete-older-than 7d
        nix-store --gc
      '';
      description = "Delete old NixOS generations and unused packages";
    };
  };
}
