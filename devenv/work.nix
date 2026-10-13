# Work VPN / DNS scripts.
{ ... }:
{
  env = {
    OPENVPN_CONFIG = "/home/astroreen/.local/share/nixos/hosts/astroreen/profiles/terminal/openvpn/work.ovpn";
    COMPANY_DNS = "192.168.1.8";
  };

  scripts = {
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

    stop-work = {
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
  };
}
