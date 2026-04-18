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

    switch-server = {
      exec = "git add . && sudo nixos-rebuild switch --flake .#server";
      description = "Switch to the new NixOS server configuration";
    };

    switch-laptop = {
      exec = "git add . && sudo nixos-rebuild switch --flake .#laptop";
      description = "Switch to the new NixOS laptop configuration";
    };

    test-laptop = {
      exec = "git add . && sudo nixos-rebuild test --flake .#laptop";
      description = "Test the new NixOS laptop configuration";
    };

    test-server = {
      exec = "git add . && sudo nixos-rebuild test --flake .#server";
      description = "Test the new NixOS server configuration";
    };

    rollback-laptop = {
      exec = "sudo nixos-rebuild switch --flake .#laptop --rollback";
      description = "Rollback to the previous NixOS laptop configuration";
    };

    rollback-server = {
      exec = "sudo nixos-rebuild switch --flake .#server --rollback";
      description = "Rollback to the previous NixOS server configuration";
    };

    boot-laptop = {
      exec = "git add . && sudo nixos-rebuild boot --flake .#laptop";
      description = "Build the new configuration for laptop and make it the boot default";
    };

    boot-server = {
      exec = "git add . && sudo nixos-rebuild boot --flake .#server";
      description = "Build the new configuration for server and make it the boot default";
    };

    build-laptop = {
      exec = "git add . && sudo nixos-rebuild build --flake .#laptop";
      description = "Build the new configuration for laptop, but neither activate it nor add it to the GRUB boot menu";
    };

    build-server = {
      exec = "git add . && sudo nixos-rebuild build --flake .#server";
      description = "Build the new configuration for serverq, but neither activate it nor add it to the GRUB boot menu";
    };

    dry-build-laptop = {
      exec = "git add . && sudo nixos-rebuild dry-build --flake .#laptop";
      description = "Show what store paths would be built or downloaded by any of the operations above, but otherwise do nothing.";
    };

    dry-build-server = {
      exec = "git add . && sudo nixos-rebuild dry-build --flake .#server";
      description = "Show what store paths would be built or downloaded by any of the operations above, but otherwise do nothing.";
    };

    dry-activate-laptop = {
      exec = "git add . && sudo nixos-rebuild dry-activate --flake .#laptop";
      description = "Build the new configuration, but instead of activating it, show what changes would be performed by the activationq.";
    };

    dry-activate-server = {
      exec = "git add . && sudo nixos-rebuild dry-activate --flake .#server";
      description = "Build the new configuration, but instead of activating it, show what changes would be performed by the activation.";
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

  tasks = {

    "nixos:update-flake" = {
      exec = "update-flake";
      description = "Update the Nix flake";
      before = [
        "nixos:switch-server"
        "nixos:switch-laptop"
      ];
    };

    "nixos:switch-server" = {
      exec = "switch-server";
      description = "Switch to the new NixOS server configuration";
    };

    "nixos:switch-laptop" = {
      exec = "switch-laptop";
      description = "Switch to the new NixOS laptop configuration";
    };

    "nixos:delete-garbage" = {
      exec = "delete-garbage";
      description = "Delete old NixOS generations and unused packages";
      after = [
        "nixos:switch-server"
        "nixos:switch-laptop"
      ];
    };
  };
}
