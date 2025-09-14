{ pkgs, lib, config, inputs, ... }:

{
    env = {
        OPENVPN_CONFIG = "/home/astroreen/.local/share/nixos/modules/tui/openvpn/work.ovpn";
    };

    scripts = {
        start-vpn = {
            exec = "sudo openvpn --config $OPENVPN_CONFIG";
            description = "Start OpenVPN with the specified configuration file";
        };

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
    };

    tasks = {
        "work:start-vpn" = {
            exec = "start-vpn";
            description = "Start OpenVPN with the specified configuration file";
        };

        "nixos:update-flake" = {
            exec = "update-flake";
            description = "Update the Nix flake";
        };

        "nixos:switch-server" = {
            exec = "switch-server";
            description = "Switch to the new NixOS server configuration";
        };

        "nixos:switch-laptop" = {
            exec = "switch-laptop";
            description = "Switch to the new NixOS laptop configuration";
        };
    };

    processes = {
        vpn = {
            exec = "start-vpn";
        };
    };
}
