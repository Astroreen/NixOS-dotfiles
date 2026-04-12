{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.ai.skill;
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

  # Always-on snippet from the caveman README:
  # https://github.com/JuliusBrussee/caveman#install — "Want it always on?"
  # Materialized as a nix-store file to avoid shell heredoc interpolation issues.
  cavemanAlwaysOnFile = pkgs.writeText "caveman-always-on.md" ''


    ---

    ## Caveman Mode (Always On)

    Terse like caveman. Technical substance exact. Only fluff die.
    Drop: articles, filler (just/really/basically), pleasantries, hedging.
    Fragments OK. Short synonyms. Code unchanged.
    Pattern: [thing] [action] [reason]. [next step].
    ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.
    Code/commits/PRs: normal. Off: "stop caveman" / "normal mode".
  '';
in
{
  options = with lib; {
    custom.ai.skill = {
      learn = {
        enable = mkEnableOption "Learn skill — self-improving skill that learns from user feedback and updates itself over time";
      };

      caveman = {
        enable = mkEnableOption "Caveman skill — token-efficient caveman-speak mode";
        alwaysOn = mkEnableOption "Append caveman always-on snippet to AGENTS.md so the mode is active every session";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.learn.enable {
      # Copy learn skill
      home.activation.copyLearnSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir ./learn "${baseCfg.settings.configDir}/skills/learn"
      );
    })

    (lib.mkIf cfg.caveman.enable {
      # Copy caveman skills from upstream flake input (github:JuliusBrussee/caveman)
      # into ~/.config/opencode/skills/. Runs after opencode's own skills copy so
      # local skills (e.g. `learn`) and caveman skills coexist.
      home.activation.copyCavemanSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir "${inputs.caveman}/skills" "${baseCfg.settings.configDir}/skills"
      );
    })

    (lib.mkIf (cfg.caveman.enable && cfg.caveman.alwaysOn) {
      # Append the "always on" snippet to the opencode AGENTS.md that was just
      # copied by opencode's copyOpencodeAgentsDoc activation. Source AGENTS.md
      # in the nix store stays untouched; we only mutate the user-writable copy.
      home.activation.cavemanAlwaysOnSnippet = lib.hm.dag.entryAfter [ "copyOpencodeAgentsDoc" ] ''
        cat ${cavemanAlwaysOnFile} >> ${baseCfg.settings.configDir}/AGENTS.md
      '';
    })

  ];
}
