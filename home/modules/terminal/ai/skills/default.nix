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

  copyDir = src: dest: ''
    mkdir -p ${dest}
    for item in ${src}/*; do
      name=$(basename "$item")
      rm -rf "${dest}/$name"
      cp -r "$item" "${dest}/$name"
    done
    chmod -R 777 ${dest}
    find ${dest} -type d -exec chmod 755 {} \;
  '';

  copyOne = src: dest: ''
    rm -rf "${dest}"
    cp -r ${src} "${dest}"
    chmod -R 777 "${dest}"
    find "${dest}" -type d -exec chmod 755 {} \;
  '';

  # Copy only the entries of `srcDir` whose names are in `names`
  # (empty names list = copy everything, upstream default).
  copySelected =
    srcDir: names: destDir:
    let
      entries = builtins.readDir srcDir;
      wanted = if names == [ ] then entries else lib.filterAttrs (n: _: lib.elem n names) entries;
    in
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n: _: copyOne "${srcDir}/${n}" "${destDir}/${n}") wanted
    );

  # Skill catalogs, read from the pinned flake inputs at eval time. Shared by
  # the global assertions below and the copy blocks in `config` — this is why
  # they live here and not inside the mkIf blocks.
  #
  # Matt Pocock skills live in a nested layout: skills/<category>/<name>/.
  # Only engineering/ and productivity/ are exposed — misc/ is Matt-specific,
  # in-progress/ is WIP stubs, deprecated/ is dead. New upstream skills become
  # available after `nix flake update mattpocock-skills` — add them to
  # `include` to adopt.
  mattPocockRoot = "${inputs.mattpocock-skills}/skills";
  mattPocockCategories = [
    "engineering"
    "productivity"
  ];
  mattPocockSkills = lib.foldl' (
    acc: category:
    acc
    // lib.mapAttrs' (name: _: lib.nameValuePair name "${mattPocockRoot}/${category}/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${mattPocockRoot}/${category}")
    )
  ) { } mattPocockCategories;

  # Caveman skills are flat: skills/<name>/. Upstream also ships shared
  # non-skill files (compile.mjs, registry.json, ...) — copySelected accepts
  # any entry by name, so the catalog is everything readDir sees, minus the
  # prebuilt `generated/` bundle (aider/codex/gemini/...) we don't use.
  cavemanSkills = builtins.removeAttrs (builtins.readDir "${inputs.caveman}/skills") [ "generated" ];

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
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Names of entries under the caveman input's skills/ dir to copy. Empty = copy all (upstream default).";
        };
      };

      # Skills from github:mattpocock/skills (MIT), fetched via flake input.
      matt-pocock = {
        enable = mkEnableOption "Matt Pocock skills — engineering/productivity skills from github:mattpocock/skills";
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of skill directories (under engineering/ or productivity/ in
            the mattpocock-skills input) to copy. Empty = copy all of them.
          '';
        };
      };

      # Local skill payload (skills/unslop/SKILL.md), copied verbatim.
      unslop = {
        enable = mkEnableOption "Unslop skill — strip AI writing tells from prose";
      };
    };
  };

  config = lib.mkMerge [
    # Eval-time guards against typos in include lists (assertions stay lazy,
    # unlike a bare `assert`, which would force cfg during merging).
    {
      assertions = [
        {
          assertion = lib.all (name: builtins.hasAttr name cavemanSkills) cfg.caveman.include;
          message = ''
            custom.ai.skill.caveman.include: unknown skills: ${
              toString (lib.filter (name: !(builtins.hasAttr name cavemanSkills)) cfg.caveman.include)
            }
            Available: ${toString (lib.attrNames cavemanSkills)}'';
        }
        {
          assertion = lib.all (name: builtins.hasAttr name mattPocockSkills) cfg.matt-pocock.include;
          message = ''
            custom.ai.skill.matt-pocock.include: unknown skills: ${
              toString (lib.filter (name: !(builtins.hasAttr name mattPocockSkills)) cfg.matt-pocock.include)
            }
            Available: ${toString (lib.attrNames mattPocockSkills)}'';
        }
      ];
    }

    (lib.mkIf cfg.learn.enable {
      # Copy learn skill
      home.activation.copyLearnSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir ./learn "${baseCfg.settings.configDir}/skills/learn"
      );
    })

    (lib.mkIf cfg.caveman.enable {
      # Copy selected caveman skills from upstream flake input
      # (github:JuliusBrussee/caveman) into ~/.config/opencode/skills/.
      # Runs after opencode's own skills copy so local skills and caveman
      # skills coexist.
      home.activation.copyCavemanSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copySelected "${inputs.caveman}/skills" cfg.caveman.include "${baseCfg.settings.configDir}/skills"
        # Upstream ships a prebuilt `generated/` bundle (aider/codex/gemini/...)
        # we don't use — drop it instead of letting it accumulate.
        + ''
          rm -rf "${baseCfg.settings.configDir}/skills/generated"
        ''
      );
    })

    (lib.mkIf cfg.matt-pocock.enable {
      # Copy selected matt-pocock skills from the flake input into
      # ~/.config/opencode/skills/<name>/. Empty include = copy all.
      home.activation.copyMattPocockSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatMapStrings
          (name: copyOne mattPocockSkills.${name} "${baseCfg.settings.configDir}/skills/${name}")
          (if cfg.matt-pocock.include == [ ] then lib.attrNames mattPocockSkills else cfg.matt-pocock.include)
      );
    })

    (lib.mkIf cfg.unslop.enable {
      # Copy the local unslop skill payload into ~/.config/opencode/skills/unslop/.
      home.activation.copyUnslopSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        copyDir ./unslop "${baseCfg.settings.configDir}/skills/unslop"
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
