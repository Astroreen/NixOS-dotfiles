{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.ai.skill;

  # Bundled local skills: every directory next to this file. Selected by name
  # via `custom.ai.skill.local.include` (empty = deploy none).
  bundledDir = ./.;
  bundledSkills = lib.filterAttrs (_: type: type == "directory") (builtins.readDir bundledDir);

  # Skill catalogs, read from the pinned flake inputs at eval time. Shared by
  # the global assertions below and the source list in `config` — this is why
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
  # non-skill files (compile.mjs, registry.json, ...) — `include` accepts any
  # entry by name, so the catalog is everything readDir sees, minus the
  # prebuilt `generated/` bundle (aider/codex/gemini/...) we don't use.
  cavemanSkills = builtins.removeAttrs (builtins.readDir "${inputs.caveman}/skills") [ "generated" ];

  # Ordered source list for the merged skills directory. Later entries win on a
  # name collision, so the upstream sets shadow the bundled local ones (e.g.
  # local `code-review` loses to matt-pocock's).
  skillSources =
    map (name: "${bundledDir}/${name}") cfg.local.include
    ++ map (name: "${inputs.caveman}/skills/${name}") cfg.caveman.include
    ++ map (name: mattPocockSkills.${name}) (
      if cfg.matt-pocock.include == [ ] then lib.attrNames mattPocockSkills else cfg.matt-pocock.include
    );

  # opencode only scans `skills/<name>/SKILL.md`, so the whole set has to land
  # in one directory. Built as a store path; home-manager lndir's it into
  # ~/.config/opencode/skills/ (real directory, read-only per-file symlinks),
  # which keeps runtime-added skills (astrocode extraDirs, learned patterns)
  # possible.
  skillsDir = pkgs.runCommandLocal "opencode-skills" { } ''
    mkdir -p $out
    ${lib.concatMapStrings (src: ''
      name=$(basename ${lib.escapeShellArg src})
      rm -rf "$out/$name"
      cp -r --no-preserve=mode ${lib.escapeShellArg src} "$out/$name"
    '') skillSources}
  '';

  # Always-on snippet from the caveman README:
  # https://github.com/JuliusBrussee/caveman#install — "Want it always on?"
  # Exposed as an option so the importing profile can splice it into
  # `programs.opencode.context` (AGENTS.md) instead of appending at activation.
  cavemanAlwaysOnSnippet = ''

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
      # Bundled local skill set (this module's directory). Opt-in by name.
      local = {
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of bundled local skills (directories next to
            skills/default.nix) to deploy to `~/.config/opencode/skills/`.
            Empty = deploy none.
          '';
        };
      };

      caveman = {
        enable = mkEnableOption "Caveman skill — token-efficient caveman-speak mode";
        alwaysOn = mkEnableOption "Append caveman always-on snippet to AGENTS.md so the mode is active every session";
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Names of entries under the caveman input's skills/ dir to copy. Empty = copy all (upstream default).";
        };
        alwaysOnSnippet = mkOption {
          type = types.lines;
          readOnly = true;
          default = cavemanAlwaysOnSnippet;
          description = ''
            Text appended to `programs.opencode.context` (AGENTS.md) when
            `custom.ai.skill.caveman.alwaysOn` is enabled. Read-only; derived
            from the caveman README.
          '';
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
    };
  };

  config = lib.mkMerge [
    # Eval-time guards against typos in include lists (assertions stay lazy,
    # unlike a bare `assert`, which would force cfg during merging).
    {
      assertions = [
        {
          assertion = lib.all (name: builtins.hasAttr name bundledSkills) cfg.local.include;
          message = ''
            custom.ai.skill.local.include: unknown skills: ${
              toString (lib.filter (name: !(builtins.hasAttr name bundledSkills)) cfg.local.include)
            }
            Available: ${toString (lib.attrNames bundledSkills)}'';
        }
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

    (lib.mkIf (skillSources != [ ]) {
      # Declarative alternative to copying into skills/ at
      # activation. The whole catalog is materialized as one store directory
      # (see skillsDir above); home-manager lndirs it into place.
      programs.opencode.skills = "${skillsDir}";
      programs.claude-code.skills = "${skillsDir}";
    })
  ];
}
