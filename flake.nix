{
  description = "A modular NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"; # Keep stable as fallback or for servers

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning, used by nixos-anywhere to install server hosts.
    disko = {
      url = "github:nix-community/disko";
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

    # Matt Pocock skills: engineering/productivity opencode skills (MIT).
    # Not a flake — consumed as a plain source tree, same as caveman.
    # Selected skills copied into ~/.config/opencode/skills/ via
    # custom.ai.skill.matt-pocock.include (see home/modules/terminal/ai/skills/).
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };

    # Astrocode: model-aware opencode plugin (agent personas, fallback, slash
    # commands). Real flake — packages.default is a minimal filtered copy
    # (agents/, skills/, src/, package.json, tsconfig.json, README.md),
    # deployed via home.activation into ~/.config/opencode/plugins.
    astrocode.url = "github:Astroreen/astrocode";

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

    # HyprMod — GTK4 settings app for Hyprland. Writes to its own mutable
    # ~/.config/hypr/hyprland-gui.lua; the include is added declaratively in
    # home/astroreen/profiles/apps/hyprmod.nix so its first-run setup never
    # rewrites the read-only home-manager symlink for hyprland.lua.
    hyprmod = {
      url = "github:BlueManCZ/hyprmod";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode v2 (npm @opencode/cli line). nixpkgs still packages the v1 line
    # (opencode-ai 1.19.0), but t3code >= 0.0.46 marks opencode >= 2.0.18 as
    # "supported" and 1.14.19-1.x as "graceful" (limited compatibility) in its
    # driver matrix. Upstream ships Nix expressions since v2; the tag pins the
    # release that also locks node_modules hashes (nix/hashes.json).
    opencode-v2.url = "github:anomalyco/opencode/v2.0.28";

    # Nixdatifier: tray app for NixOS generations, diffs and flake input updates.
    # Imported via its Home Manager module in home/astroreen/profiles/apps/nixdatifier.nix.
    nixdatifier = {
      url = "github:Muddyblack/nixdatifier";
      inputs.nixpkgs.follows = "nixpkgs";
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
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        }
      );

      # Instantiate stable pkgs exactly once per system
      pkgsStableFor = forAllSystems (
        system:
        import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        }
      );

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

          nixosSystem = nixpkgs.lib.nixosSystem {
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
            ]
            ++ extraModules; # Allow passing extra modules from host configuration
          };
        in
        {
          nixosConfigurations = {
            "${username}@${host}" = nixosSystem;
            # Bare host name alias: tools that pick the configuration by
            # `hostname -s` (nixdatifier update previews) find it too.
            ${host} = nixosSystem;
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
            ]
            ++ (if extraHomeModuleSettings != { } then [ extraHomeModuleSettings ] else [ ]);
          };
        };

      # Extra NixOS modules for every host importing hosts/<user>/common/server.
      serverModules = [
        inputs.disko.nixosModules.disko
        home-manager.nixosModules.home-manager # HM for the `agent` account
      ];

      hosts = [
        {
          host = "laptop";
          username = "astroreen";
          extraModules = [ inputs.hyprland.nixosModules.default ];
        }
        {
          host = "pc";
          username = "astroreen";
          extraModules = [ inputs.hyprland.nixosModules.default ];
        }
        {
          host = "aktkc";
          username = "astroreen";
          extraModules = serverModules;
        }
      ];

      hostConfigs = map createHost hosts;
    in
    {
      nixosConfigurations = builtins.foldl' (a: b: a // b) { } (
        map (h: h.nixosConfigurations) hostConfigs
      );

      homeConfigurations = builtins.foldl' (a: b: a // b) { } (map (h: h.homeConfigurations) hostConfigs);
    };
}
