{ pkgs, ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    settings = {
      auto-optimise-store = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    package = pkgs.lixPackageSets.stable.lix;
  };

  # System wide packages
  environment.systemPackages = with pkgs; [
    # Development tools
    vim # Vim text editor

    # Libraries
    gnugrep # GNU grep
    gawk # GNU Awk

    # System utilities
    coreutils # GNU Core Utilities
    tree # `tree` command
    pciutils # `lspci` command
    cmake # CMake build system
    gcc14 # GNU Compiler Collection
  ];
}
