{ lib, pkgs, ... }:
let
  configDir = ".config/opencode";

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
    ../mcps.nix
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      theme = "gruvbox";
      plugin = [
        "@franlol/opencode-md-table-formatter@latest"
        "@mohak34/opencode-notifier@latest"
        "opencode-vibeguard@latest"
      ];
    };
  };

  # Copy AGENTS.md
  home.activation.copyOpencodeAgentsDoc = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyFile ../AGENTS.md "${configDir}/AGENTS.md"
  );

  # Copy vibeguard config
  home.activation.copyVibeguardConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyFile ./vibeguard.config.json "${configDir}/vibeguard.config.json"
  );

  # Copy agents folder
  home.activation.copyOpencodeAgentsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyDir ../agents "${configDir}/agents"
  );

  # Copy commands folder
  home.activation.copyOpencodeCommandsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyDir ../commands "${configDir}/commands"
  );

  # Copy skills folder
  home.activation.copyOpencodeSkillsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyDir ../skills "${configDir}/skills"
  );

}
