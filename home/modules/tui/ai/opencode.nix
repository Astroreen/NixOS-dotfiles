{ lib, pkgs, ... }:
let
  configDir = ".config/opencode";
  mcps = import ./mcps.nix;

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
  programs.opencode = {
    enable = true;
    # Not using settings since it would symlink the config file, thus restricting write permissions
  };

  # Copy AGENTS.md
  home.activation.copyOpencodeAgentsDoc = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyFile ./AGENTS.md "${configDir}/AGENTS.md"
  );

  # Copy agents folder
  home.activation.copyOpencodeAgentsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyDir ./agents "${configDir}/agents"
  );

  # Copy commands folder
  home.activation.copyOpencodeCommandsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    copyDir ./commands "${configDir}/commands"
  );

}
