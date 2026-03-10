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
    
    # Do not override nixpkgs version of Hyprland, as it may break cachix and other things.
    hyprland.url = "github:hyprwm/Hyprland";

    app2unit = {
      url = "github:soramanew/app2unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs: # Put everything else inside of 'inputs' argument
    let
      createHost =
        {
          host,
          username,
          systemVersion ? "x86_64-linux",
          extraSpecialArgs ? { },
          extraHomeModuleSettings ? { },
          extraModules ? [ ],
          ...
        }:
        {
          nixosConfigurations.${host} = nixpkgs.lib.nixosSystem rec {
            # Arguments
            system = systemVersion;
            specialArgs = {
              inherit inputs host;
              pkgs-stable = import inputs.nixpkgs-stable {
                inherit system;
                config.allowUnfree = true;
              };
            }
            // extraSpecialArgs; # Allow passing extra special args from host configuration

            # Modules
            modules = [
              ./overlays # Overlays
              ./hosts/${host}/configuration.nix # Host configuration
              inputs.hyprland.nixosModules.default # Hyprland default module
              home-manager.nixosModules.home-manager # Home manager module
              (
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "backup";

                    # Pass arguments to every home-manager file
                    extraSpecialArgs = {
                      inherit inputs;
                      inherit (inputs) pkgs-stable;
                    };

                    # User specific config file
                    users.${username} = {
                      imports = [
                        ./home/${username}/${host}/home.nix
                        {
                          home = {
                            inherit username;
                            homeDirectory = "/home/${username}";
                            stateVersion = "25.11";
                          };
                        }
                      ];
                    };
                  };
                }
                // extraHomeModuleSettings
              )
            ]
            ++ extraModules; # Allow passing extra modules from host configuration
          };
        };

      hosts = [
        {
          host = "laptop";
          username = "astroreen";
        }
        {
          host = "server";
          username = "astroreen";
        }
      ];
    in
    {
      nixosConfigurations = builtins.foldl' (a: b: a // b) { } (
        map (h: h.nixosConfigurations) (map createHost hosts)
      );
    };
}
