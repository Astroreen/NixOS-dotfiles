{
  lib,
  pkgs,
  config,
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
    ../. # default.nix of ai folder
    ../mcps.nix
    ../meridian.nix
  ];

  # Enable Meridian for Claude Pro/Max integration into OpenCode
  custom.ai = {
    meridian = {
      enable = false;
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
      theme = "gruvbox";
      plugin = [
        "@franlol/opencode-md-table-formatter@latest"
        "@mohak34/opencode-notifier@0.1.36"
        "opencode-vibeguard@latest"
        "@tarquinen/opencode-dcp@3.1.6"
        "opencode-anthropic-auth"
        "opencode-claude-auth"
      ];
    };
  };

  home.activation = {
    # Copy AGENTS.md
    copyOpencodeAgentsDoc = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      copyFile ../AGENTS.md "${baseCfg.settings.configDir}/AGENTS.md"
    );

    # Copy oh-my-opencode config
    copyOhMyOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      copyFile ./oh-my-opencode.jsonc "${baseCfg.settings.configDir}/oh-my-opencode.config.jsonc"
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
      copyDir ../commands "${baseCfg.settings.configDir}/commands"
    );
  };
}
