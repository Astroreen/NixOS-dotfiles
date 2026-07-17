{ pkgs, config, ... }:
{
  # Default choices
  imports = [
    ./zsh.nix
    ./kitty.nix
  ];

  # Apply changes through home-manager and nixos system-wide configuration
  programs = {
    bash.enable = true;
    bash.enableCompletion = true;

    fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = ./assets/octane_avatar.jpg;
          width = 16;
          height = 7;
          padding = {
            right = 2;
          };
        };
        display = {
          size = {
            binaryPrefix = "si";
          };
          color = "blue";
          separator = ": ";
        };
        modules = [
          {
            type = "datetime";
            key = "Date & Time";
            format = "{1}-{3}-{11} {14}:{17}:{20}";
          }

          "break"

          {
            type = "cpuusage";
            key = "CPU";
            format = "{1}";
          }
          {
            type = "memory";
            key = "Memory";
            format = "{3} ({1} / {2})";
          }
          "uptime"

          "break"

          {
            type = "media";
            key = "Media";
            format = "{1}";
          }
        ];
      };
    };

    lsd = {
      enable = true;
      package = pkgs.lsd;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        batgrep
        batwatch
      ];
    };

    git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user.name = "astroreen";
        user.email = "astroreen@gmail.com";
      };

      #aliases = {
      #    commit = "commit -m ''";
      #};
    };

    fd.enable = true;
  };

  home.shellAliases = {
    nixconfig = "cd ${config.home.homeDirectory}/.local/share/nixos";
    cat = "bat";
  };
}
