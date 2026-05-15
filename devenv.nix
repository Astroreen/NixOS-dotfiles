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

    switch = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild switch --flake ".#$host"
      '';
    };

    try = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild test --flake ".#$host"
      '';
    };

    rollback = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        sudo nixos-rebuild switch --flake ".#$host" --rollback
      '';
    };

    boot = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild boot --flake ".#$host"
      '';
    };

    build = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild build --flake ".#$host"
      '';
    };

    dry-build = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild dry-build --flake ".#$host"
      '';
    };

    dry-activate = {
      exec = ''
        host="''${1:?Usage: switch <laptop|server>}"
        git add . && sudo nixos-rebuild dry-activate --flake ".#$host"
      '';
    };

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

    start-whisper = {
      # Start whisper server for voice transcription
      # ggml-tiny.bin ggml-base.bin ggml-large-v3-turbo-q5_0.bin
      description = "Start voice transcribing service";
      exec = "whisper-server -m /home/astroreen/apps/whisper.cpp/models/ggml-medium.bin --host 0.0.0.0 --port 7777 --language auto";
    };
  };
}
