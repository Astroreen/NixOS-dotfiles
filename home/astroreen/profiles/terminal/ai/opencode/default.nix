{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  baseCfg = config.custom.ai;

  copyFile = src: dest: ''
    mkdir -p $(dirname ${dest})
    cp ${src} ${dest}
    chmod 777 ${dest}
  '';

  copyDir = src: dest: ''
    mkdir -p ${dest}
    cp -r ${src}/* ${dest}/
    chmod -R 777 ${dest}
    find ${dest} -type d -exec chmod 755 {} \;
  '';
in
{
  imports = [
    ../../../../../modules/terminal/ai # default.nix of ai folder
  ];

  # Enable Meridian for Claude Pro/Max integration into OpenCode
  custom.ai = {
    meridian = {
      enable = true;
      enableOpencodeIntegration = true;
    };

    skill = {
      learn.enable = true;

      # Caveman skill — token-efficient mode, always on
      caveman = {
        enable = true;
        alwaysOn = true;
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      # Yolo: stop permission prompts. Only external_directory (and doom_loop)
      # default to "ask" — bash/read/edit/webfetch are already "allow".
      # Scoped to external_directory so the default .env / .env.* read deny
      # (secret protection) stays intact.
      permission = {
        external_directory = "allow";
        bash = "allow";
        read = "allow";
        edit = "allow";
        webfetch = "allow";
      };

      plugin = [
        "@franlol/opencode-md-table-formatter@latest"
        "@mohak34/opencode-notifier"
        "@tarquinen/opencode-dcp"
        "opencode-vibeguard@latest"
        "opencode-anthropic-auth"
        "opencode-claude-auth"
      ];
    };

    tui = {
      theme = "gruvbox";
    };

    # Headless server, started with the user systemd session (default.target).
    # Loopback only; --mdns advertises it for LAN discovery.
    web = {
      enable = true;
      extraArgs = [
        "--hostname"
        "127.0.0.1"
        "--port"
        "4096"
        "--mdns"
      ];
    };
  };

  home = {
    packages = [
      pkgs.gh # GitHub CLI - required by oh-my-openagent's GitHub automation features
    ];

    activation = {
      # Copy AGENTS.md
      copyOpencodeAgentsDoc = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyFile ../CustomPrompt.md "${baseCfg.settings.configDir}/AGENTS.md"
      );

      # Copy vibeguard config
      copyVibeguardConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyFile ./vibeguard.config.json "${baseCfg.settings.configDir}/vibeguard.config.json"
      );

      # Copy agents folder
      copyOpencodeAgentsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir ../agents "${baseCfg.settings.configDir}/agents"
      );

      # Copy commands folder
      copyOpencodeCommandsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir ../../../../../modules/terminal/ai/commands "${baseCfg.settings.configDir}/commands"
      );

      # Astrocode plugin: copy the full source tree from the flake input
      # (local-plugin-dir mechanism requires imports/agents/skills alongside
      # the entry file, so it can't be a single copied file) into a writable
      # subdirectory, then symlink a top-level entry file into plugins/ so
      # opencode's loader discovers it even if it only scans top-level files.
      copyAstrocodePlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir inputs.astrocode.packages.${pkgs.system}.default
          "${baseCfg.settings.configDir}/plugins/.astrocode-src"
      );

      # Relative target so it resolves inside the link's own directory
      # (configDir is a relative path; an absolute-looking target here would
      # be interpreted relative to plugins/ and end up broken).
      linkAstrocodePlugin = lib.hm.dag.entryAfter [ "copyAstrocodePlugin" ] ''
        mkdir -p "${baseCfg.settings.configDir}/plugins"
        ln -sf ".astrocode-src/src/index.ts" \
               "${baseCfg.settings.configDir}/plugins/astrocode.ts"
      '';

      # astrocode's own config (model, agents, fallback, skills, reasoning).
      # Deployed to ~/.opencode/astrocode.jsonc: astrocode walks from each
      # project dir up to $HOME collecting astrocode.jsonc layers, so this
      # applies to every project while a project-local file still wins.
      copyAstrocodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyFile ./astrocode.jsonc "${config.home.homeDirectory}/.opencode/astrocode.jsonc"
      );

      # Hide model thinking blocks by default. There is no opencode config key
      # for this — the TUI persists it in mutable runtime state
      # (~/.local/state/opencode/kv.json, key "thinking_mode"; upstream default
      # "hide"). Merge it in so the other UI preferences in that file survive.
      hideOpencodeThinking = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        kv="${config.home.homeDirectory}/.local/state/opencode/kv.json"
        if ${pkgs.jq}/bin/jq -e . "$kv" >/dev/null 2>&1; then
          ${pkgs.jq}/bin/jq '.thinking_mode = "hide"' "$kv" > "$kv.tmp" && mv "$kv.tmp" "$kv"
        else
          mkdir -p "$(dirname "$kv")"
          printf '%s' '{"thinking_mode":"hide"}' > "$kv"
        fi
      '';
    };

    shellAliases = {
      oc = "opencode";
    };
  };
}
