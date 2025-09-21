{ pkgs, lib, config, inputs, ... }:

{
    env = {
        OPENVPN_CONFIG = "/home/astroreen/.local/share/nixos/modules/tui/openvpn/work.ovpn";
        COMPANY_DNS="192.168.1.8";
        BACKUP_FILE="/tmp/resolv.conf.backup";
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

        delete-garbage = {
            exec = "nix-collect-garbage --delete-older-than 7d";
            description = "Delete old NixOS generations and unused packages";
        };

        add-work-dns = {
            description = "Add work DNS server";
            exec = ''
                echo "Setting up VPN DNS..."
    
                # Backup current resolv.conf
                sudo cp /etc/resolv.conf "$BACKUP_FILE"
    
                # Create new resolv.conf with company DNS first
                {
                    echo "# VPN DNS Configuration"
                    echo "nameserver $COMPANY_DNS"
                    # Original DNS servers
                    echo "nameserver 192.168.50.167"
                    echo "nameserver 192.168.50.1"
                    # Fallback DNS servers
                    echo "nameserver 8.8.8.8"
                    echo "nameserver 8.8.4.4"
                    echo "options edns0"
                } | sudo tee /etc/resolv.conf > /dev/null
    
                echo "DNS configured for VPN (Primary: $COMPANY_DNS)"
            '';
        };

        start-vpn = {
            description = "Start OpenVPN with the specified configuration file and its dns server";
            exec = "sudo openvpn --config $OPENVPN_CONFIG";
        };

        delete-work-dns = {
            description = "Stop work DNS server";
            exec = ''
                echo "Restoring original DNS..."
    
                if [ -f "$BACKUP_FILE" ]; then
                    sudo cp "$BACKUP_FILE" /etc/resolv.conf
                    sudo rm "$BACKUP_FILE"
                    echo "Original DNS restored"
                else
                    # Fallback to original DNS servers
                    {
                        # Original DNS servers
                        echo "nameserver 192.168.50.167"
                        echo "nameserver 192.168.50.1"
                        # Fallback DNS servers
                        echo "nameserver 8.8.8.8"
                        echo "nameserver 8.8.4.4"
                        echo "options edns0"
                    } | sudo tee /etc/resolv.conf > /dev/null
                    echo "Reset to default DNS"
                fi
            '';
        };

        start-work = {
            description = "List of scripts to start work environment";
            exec = ''
                add-work-dns
                start-vpn
                delete-work-dns
            '';
        };
    };

    tasks = {
        "work:start-vpn" = {
            exec = "add-work-dns && start-vpn";
            description = "Start OpenVPN with the specified configuration file";
        };

        "work:stop-vpn" = {
            exec = "stop-vpn";
            description = "Stop OpenVPN and restore the original DNS settings";
            after = [ "work:start-vpn" ];
        };

        "nixos:update-flake" = {
            exec = "update-flake";
            description = "Update the Nix flake";
            before = [ "nixos:switch-server" "nixos:switch-laptop" ];
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
            after = [ "nixos:switch-server" "nixos:switch-laptop" ];
        };
    };
}
