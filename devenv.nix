{
  pkgs,
  ...
}:

{
  packages = with pkgs; [
    deadnix
    statix
  ];

  env = {
    OPENVPN_CONFIG = "/home/astroreen/.local/share/nixos/hosts/modules/tui/openvpn/work.ovpn";
    COMPANY_DNS = "192.168.1.8";
  };

  scripts = {
    update-flake = {
      exec = "nix flake update --extra-experimental-features nix-command --extra-experimental-features flakes";
      description = "Update the Nix flake";
    };

    nixos = {
      description = "Manage NixOS configuration (switch, test, boot, build, dry-build, dry-activate, rollback)";
      exec = ''
        action="''${1:?Usage: nixos <action> <host>}"
        host="''${2:?Usage: nixos <action> <host>}"

        if [ "$action" = "rollback" ]; then
          sudo nixos-rebuild switch --no-reexec --flake ".#$host" --rollback
        else
          git add .
          sudo nixos-rebuild "$action" --no-reexec --flake ".#$host"
        fi
      '';
    };
    nx.exec = "nixos $@"; # Alias for nixos-rebuild

    home = {
      description = "Manage Home Manager configuration (switch, build, rollback)";
      exec = ''
        action="''${1:?Usage: home <action> <host>}"
        host="''${2:?Usage: home <action> <host>}"

        if [ "$action" = "rollback" ]; then
          home-manager switch --rollback --flake ".#astroreen@$host"
        else
          git add .
          home-manager "$action" --flake ".#astroreen@$host"
        fi
      '';
    };
    hm.exec = "home $@"; # Alias for home manager

    delete-garbage = {
      exec = ''
        nix-collect-garbage --delete-older-than 7d
        nix-store --gc
      '';
      description = "Delete old NixOS generations and unused packages";
    };

    add-work-dns = {
      description = "Add work DNS server";
      exec = ''
        echo "Setting up VPN DNS..."

        # Configure DNS for tun0 interface using systemd-resolved
        sudo resolvectl dns tun0 "$COMPANY_DNS"
        sudo resolvectl domain tun0 '~aktkc.local'

        echo "DNS configured for VPN (Primary: $COMPANY_DNS, Domain: aktkc.local)"
      '';
    };

    delete-work-dns = {
      description = "Stop work DNS server";
      exec = ''
        echo "Removing VPN DNS..."

        # Clear DNS configuration for tun0 interface
        if ip link show tun0 &>/dev/null; then
            sudo resolvectl revert tun0
            echo "VPN DNS removed"
        else
            echo "tun0 interface not found (VPN not running)"
        fi
      '';
    };

    start-work = {
      description = "Start work VPN and configure DNS";
      exec = ''
        echo "Starting work environment..."

        # Start VPN in background
        sudo openvpn --config "$OPENVPN_CONFIG" --daemon

        # Wait for tun0 to come up
        echo "Waiting for VPN interface..."
        for i in {1..10}; do
          if ip link show tun0 &>/dev/null; then
            echo "VPN interface is up"
            break
          fi
          sleep 1
        done

        # Configure DNS
        add-work-dns

        echo "Work environment ready"
      '';
    };

    end-work = {
      description = "Stop work VPN and remove DNS configuration";
      exec = ''
        echo "Stopping work environment..."

        # Remove DNS configuration
        delete-work-dns

        # Stop OpenVPN
        sudo pkill -SIGTERM openvpn

        # Wait for process to terminate
        sleep 1

        if pgrep openvpn &>/dev/null; then
          echo "Warning: OpenVPN still running, force killing..."
          sudo pkill -SIGKILL openvpn
        fi

        echo "Work environment stopped"
      '';
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

    start-whisper = {
      # Start whisper server for voice transcription
      # ggml-tiny.bin ggml-base.bin ggml-large-v3-turbo-q5_0.bin
      description = "Start voice transcribing service";
      exec = "whisper-server -m /home/astroreen/apps/whisper.cpp/models/ggml-medium.bin --host 0.0.0.0 --port 7777 --language auto";
    };
  };
}
