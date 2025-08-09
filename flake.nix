{
  description = "A modular NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11"; # Keep stable as fallback or for servers

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    hyprland.url = "github:hyprwm/Hyprland";

    app2unit = {
      url = "github:soramanew/app2unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.app2unit.follows = "app2unit";          # Override for a non-existent input 'app2unit'
      inputs.quickshell.follows = "quickshell";
    };

    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.app2unit.follows = "app2unit";          # Override for a non-existent input 'app2unit'
      inputs.caelestia-shell.follows = "caelestia-shell";
    };

    # SpotX installation (patched spotify)
    oskars-dotfiles = {
      url = "github:oskardotglobal/.dotfiles/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs: # Put everything else inside of 'inputs' argument  
  {

    # Host configurations
    nixosConfigurations = {
      # Host laptop
      laptop = nixpkgs.lib.nixosSystem rec {

        # Arguments
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
            };
        };

        # Modules
        modules = [
          ./overlays                              # Overlays
          ./hosts/laptop/configuration.nix        # Host configuration
          inputs.hyprland.nixosModules.default    # Hyperland default module
          home-manager.nixosModules.home-manager  # Home manager module
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Pass arguments to every home-manager file
            home-manager.extraSpecialArgs = {
              inherit inputs;
              pkgs-stable = inputs.pkgs-stable;
            };

            # User specific config file
            home-manager.users.astroreen = import ./home/astroreen-laptop/home.nix;
          }
        ];
      };

      server = nixpkgs.lib.nixosSystem rec {

        # Arguments
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
        };

        # Modules
        modules = [
          ./overlays                              # Overlays
          ./hosts/server/configuration.nix        # Host configuration
          inputs.hyprland.nixosModules.default    # Hyperland default module
          home-manager.nixosModules.home-manager  # Home manager module
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # Pass arguments to every home-manager file
            home-manager.extraSpecialArgs = {
              inherit inputs;
              pkgs-stable = inputs.pkgs-stable;
            };

            # User specific config file
            home-manager.users.astroreen = import ./home/astroreen-server/home.nix;
          }
        ];
      };

      # Another configurations
      # default = ...
      # desktop = ...
      # server  = ...
    };
  };
}
