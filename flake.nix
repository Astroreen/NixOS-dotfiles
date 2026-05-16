{
  description = "A modular NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"; # Keep stable as fallback or for servers

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

    # Caveman: opencode skill for terse, token-efficient responses.
    # Not a flake — consumed as a plain source tree.
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
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
            ]
            ++ extraModules; # Allow passing extra modules from host configuration
          };

          homeConfigurations."${username}@${host}" = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              system = systemVersion;
              config.allowUnfree = true;
              config.android_sdk.accept_license = true;
            };

            extraSpecialArgs = {
              inherit inputs host;
              pkgs-stable = import inputs.nixpkgs-stable {
                system = systemVersion;
                config.allowUnfree = true;
                config.android_sdk.accept_license = true;
              };
            };

            modules = [
              ./home/${username}/${host}/home.nix
              {
                home = {
                  inherit username;
                  homeDirectory = "/home/${username}";
                  stateVersion = "25.11";
                };
                programs.home-manager.enable = true;
              }
            ] ++ (if extraHomeModuleSettings != {} then [ extraHomeModuleSettings ] else []);
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

      hostConfigs = map createHost hosts;
    in
    {
      nixosConfigurations = builtins.foldl' (a: b: a // b) { } (
        map (h: h.nixosConfigurations) hostConfigs
      );

      homeConfigurations = builtins.foldl' (a: b: a // b) { } (
        map (h: h.homeConfigurations) hostConfigs
      );
    };
}
