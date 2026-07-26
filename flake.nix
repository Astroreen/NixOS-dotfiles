{
  description = "A modular NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"; # Keep stable as fallback or for servers

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not override nixpkgs version of Hyprland, as it may break cachix and other things.
    hyprland.url = "github:hyprwm/Hyprland";

    # quickshell moved from outfoxxed/quickshell to quickshell/quickshell
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      # Must share our nixpkgs so quickshell and caelestia-qml-plugin link
      # against the same Qt6 build; otherwise quickshell loads plugins built
      # against a different Qt6 minor version and refuses them as ABI-incompatible.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    # Caveman: opencode skill for terse, token-efficient responses.
    # Not a flake — consumed as a plain source tree.
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };

    # Hyprland plugins — follow this flake's hyprland input so plugin ABI
    # matches exactly what's actually running.
    # NOTE: gloview was tried and dropped (2026-07-26) — its pinned source
    # includes "hyprland/src/managers/PointerManager.hpp", but that header
    # was moved to "src/pointer/PointerManager.hpp" in our pinned Hyprland
    # rev. Real upstream incompatibility, not a packaging issue. Revisit
    # once upstream gloview catches up.
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };

    # NOTE: HyprCapture was tried and dropped (2026-07-26) — after fixing
    # several generated-header path issues (version.h, protocols/,
    # Monitor.hpp relocation), it hit a hard wall: its C++ source calls
    # `g_pCompositor->m_windows` / `->m_monitors`, members that don't exist
    # under those names in our pinned Hyprland rev. Real internal API break
    # between Hyprland versions (plugin targets ~0.55.4/0.54.3, we're on a
    # newer rolling rev), not a packaging issue. Revisit once upstream
    # catches up, or use Satty for screenshot+annotate in the meantime.
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs: # Put everything else inside of 'inputs' argument
    let
      # Define systems we support to instantiate pkgs once per system
      supportedSystems = [ "x86_64-linux" ];
      
      # Helper function to generate an attribute set '{ x86_64-linux = ...; }'
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Instantiate pkgs exactly once per system
      pkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
      });

      # Instantiate stable pkgs exactly once per system
      pkgsStableFor = forAllSystems (system: import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        config.android_sdk.accept_license = true;
      });

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
        let
          hostPkgs = pkgsFor.${systemVersion};
          hostPkgsStable = pkgsStableFor.${systemVersion};
        in
        {
          nixosConfigurations."${username}@${host}" = nixpkgs.lib.nixosSystem rec {
            # Pass pre-instantiated pkgs via modules
            pkgs = hostPkgs;
            system = systemVersion;
            
            specialArgs = {
              inherit inputs host;
              pkgs-stable = hostPkgsStable;
            }
            // extraSpecialArgs; # Allow passing extra special args from host configuration

            # Modules
            modules = [
              ./overlays # Overlays
              ./hosts/${username}/${host}/configuration.nix # Host configuration
              inputs.hyprland.nixosModules.default # Hyprland default module
            ]
            ++ extraModules; # Allow passing extra modules from host configuration
          };

          homeConfigurations."${username}@${host}" = home-manager.lib.homeManagerConfiguration {
            # Use the exact same pre-instantiated pkgs
            pkgs = hostPkgs;

            extraSpecialArgs = {
              inherit inputs host;
              pkgs-stable = hostPkgsStable;
            };

            modules = [
              ./home/${username}/${host}/home.nix
              {
                programs.home-manager.enable = true;
                home = {
                  inherit username;
                  homeDirectory = "/home/${username}";
                  stateVersion = "26.05";
                };
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
