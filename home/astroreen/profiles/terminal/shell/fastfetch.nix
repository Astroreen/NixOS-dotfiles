{ pkgs, lib, ... }:
let
  assetsDir = ./assets;
  logoFiles = builtins.attrNames (
    lib.filterAttrs (
      name: type:
      type == "regular"
      && lib.any (ext: lib.hasSuffix ext name) [
        ".png"
        ".jpg"
        ".jpeg"
      ]
    ) (builtins.readDir assetsDir)
  );
  logoPaths = map (name: "${assetsDir}/${name}") logoFiles;

  # Wraps fastfetch to pick a random logo (from ./assets) on every
  # invocation. `settings.logo` below keeps only sizing/padding - the
  # actual image path is injected here via `--logo` so it changes each
  # time a new shell opens (see zsh.nix, which calls this instead of
  # plain `fastfetch`).
  fastfetchRandomLogo = pkgs.writeShellScriptBin "fastfetch-random" ''
    logos=(
      ${lib.concatMapStringsSep "\n      " (p: ''"${p}"'') logoPaths}
    )
    logo="''${logos[RANDOM % ''${#logos[@]}]}"
    exec fastfetch --logo "$logo" "$@"
  '';

  # ESC (0x1b) via JSON decoding - nix has no `\u` string escape, and a raw
  # control byte sitting in the source file would be unreviewable. Fed
  # through `builtins.toJSON` (what programs.fastfetch uses to render the
  # config), this comes back out as the same "\u001b" the upstream config
  # uses for its ANSI color codes.
  esc = builtins.fromJSON ''"\u001b"'';
in
{
  home.packages = [ fastfetchRandomLogo ];

  # Adapted from https://github.com/decksters-lab/fastfetch-personal/blob/non-systemd/fastfetch/config.jsonc
  # (logo/source intentionally excluded - handled by fastfetch-random above).
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        height = 15;
        # padding = {
        #   top = 1;
        # };
      };
      display = {
        separator = "";
        key = {
          width = 20;
        };
      };
      modules = [
        {
          type = "custom";
          format = "${esc}[1;31m 󰊠 ${esc}[1;35m󰊠 ${esc}[1;36m󰊠 ${esc}[1;33m󰮯 ${esc}[0;33m········${esc}[1;96mTERMINALLY ${esc}[1;94mONLINE   ";
        }

        # {
        #   type = "custom";
        #   format = "┌─────────────────────────────────────────────┐";
        # }
        # {
        #   type = "os";
        #   key = "    OS";
        #   keyColor = "red";
        #   format = "{3}";
        # }
        # {
        #   type = "kernel";
        #   key = "    Kernel";
        #   keyColor = "red";
        #   format = "{2}";
        # }
        # {
        #   type = "packages";
        #   key = "  󰏖  Packages";
        #   keyColor = "red";
        #   format = "󰮯 {pacman}   {flatpak-all}";
        # }
        # {
        #   type = "display";
        #   key = "  󰍹  Display";
        #   keyColor = "green";
        #   format = "{1}x{2} {3}Hz";
        # }
        # {
        #   type = "wm";
        #   key = "  󰨇  WM";
        #   keyColor = "green";
        #   format = "{2} {5}";
        # }
        # {
        #   type = "de";
        #   key = "  󰧨  DE";
        #   keyColor = "green";
        #   format = "{2} 󰔰 {3}";
        # }
        # {
        #   type = "theme";
        #   key = "  󰏘  Theme";
        #   keyColor = "yellow";
        #   format = "{2}";
        # }
        # {
        #   type = "icons";
        #   key = "  󰉋  Icons";
        #   keyColor = "yellow";
        #   format = "{2}";
        # }
        # {
        #   type = "terminal";
        #   key = "  󰆍  Terminal";
        #   keyColor = "cyan";
        #   format = "{5} 󰔰 {6}";
        # }
        # {
        #   type = "command";
        #   key = "  󰞷  Shell";
        #   keyColor = "cyan";
        #   text = "echo $SHELL | awk -F/ '{print $NF}'";
        # }
        # {
        #   type = "custom";
        #   format = "└─────────────────────────────────────────────┘";
        # }

        {
          type = "custom";
          format = "┌─────────────────────────────────────────────┐";
        }
        # {
        #   type = "cpu";
        #   key = "    CPU";
        #   keyColor = "blue";
        #   format = "{1}";
        # }
        # {
        #   type = "gpu";
        #   key = "  󰢮  GPU";
        #   keyColor = "blue";
        #   format = "{1}";
        # }
        {
          type = "datetime";
          key = "  󰃭  Date & Time";
          keyColor = "red";
          format = "{1}-{3}-{11} {14}:{17}:{20}";
        }
        {
          type = "cpuusage";
          key = "    CPU Usage";
          keyColor = "green";
          format = "{1}";
        }
        {
          # fastfetch's built-in `gpu` module misdetects on PRIME
          # offload (NVIDIA sits behind Intel here) - shell out to
          # nvidia-smi directly instead.
          type = "command";
          key = "  󰺶  GPU Usage";
          keyColor = "yellow";
          text = ''gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null); [ -n "$gpu" ] && echo "''${gpu}%" || echo "N/A"'';
        }
        {
          type = "memory";
          key = "    Memory";
          keyColor = "blue";
          format = "{1} / {2}";
        }
        {
          type = "disk";
          key = "  󰋊  Disk";
          keyColor = "cyan";
          format = "{1} / {2} {3}";
        }
        # {
        #   type = "initsystem";
        #   key = "  󱓞  Init";
        #   keyColor = "magenta";
        #   format = "{1} 󰔰 {3}";
        # }
        # {
        #   type = "command";
        #   key = "    ${esc}[9;31msystemd${esc}[0m";
        #   keyColor = "magenta";
        #   text = ''echo "$(($(($(date +%s) - $(stat -c %W /))) / 86400 )) days liberated"'';
        # }
        {
          type = "uptime";
          key = "  󰅐  Uptime";
          keyColor = "magenta";
        }
        {
          type = "custom";
          format = "└─────────────────────────────────────────────┘";
        }
        {
          type = "colors";
          symbol = "circle";
        }

        "break"

        {
          type = "media";
          key = "  󰎇  Media";
          keyColor = "green";
          format = "{1}";
        }

      ];
    };
  };
}
