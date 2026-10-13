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
