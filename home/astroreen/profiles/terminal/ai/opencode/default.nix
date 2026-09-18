{
  lib,
  config,
  pkgs,
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
      plugin = [
        "@franlol/opencode-md-table-formatter@latest"
        "@mohak34/opencode-notifier"
        "@tarquinen/opencode-dcp"
        "opencode-vibeguard@latest"
      ];
    };
    tui = {
      theme = "gruvbox";
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

      # Copy oh-my-openagent config into the current unified config path (~/.omo/omo.jsonc).
      # NOTE: oh-my-openagent is intentionally NOT added to the global
      # `programs.opencode.settings.plugin` list below - it's enabled per-project
      # via that project's own .opencode/opencode.jsonc, so it can be toggled
      # on/off per repo. This activation only ships the shared agent/category
      # config that every enabled project should pick up.
      copyOhMyOpenAgentConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyFile ./oh-my-opencode.jsonc "${config.home.homeDirectory}/.omo/omo.jsonc"
      );

      # Remove stale pre-migration artifacts so `oh-my-openagent doctor` doesn't
      # flag a legacy config chain (see `oh-my-openagent doctor` "Legacy OMO
      # configuration remains" warning).
      removeLegacyOhMyOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        rm -f "${baseCfg.settings.configDir}/oh-my-openagent.jsonc" \
              "${baseCfg.settings.configDir}/oh-my-openagent.jsonc.migrations.json" \
              "${baseCfg.settings.configDir}"/oh-my-openagent.jsonc.bak.* \
              "${baseCfg.settings.configDir}/oh-my-opencode.config.jsonc"
      '';

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
    };

    shellAliases = {
      oc = "opencode";
    };
  };
}
