{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.ai.skill;
  ai = import ../lib.nix { inherit lib; };

  # Bundled local skills: every directory next to this file, holding a
  # frontmatter-free SKILL.md plus any resources; their metadata lives in
  # definitions.nix. Selected by name via `custom.ai.skill.local.include`
  # (empty = deploy none). SKILL.md is regenerated per CLI with a header built
  # from `custom.ai.skill.definitions.<name>`.
  bundledDir = ./.;

  skillModule =
    { name, ... }:
    {
      options =
        with lib;
        {
          src = mkOption (
            {
              type = types.path;
              description = "Skill directory; its SKILL.md is the body without frontmatter.";
            }
            // ai.optionalDefault (bundledDir + "/${name}")
          );

          license = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "License note (`license` in both headers).";
          };

          metadata = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = "Free-form `metadata` mapping (both headers).";
          };

          disableModelInvocation = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Only load the skill on explicit invocation (`disable-model-invocation`, both headers).";
          };
        }
        // ai.commonOptions {
          toolsDescription = ''
            Enabled entries become claude-code `allowed-tools` (used without a
            permission prompt while the skill is active). opencode skills have no
            tool setting, so it is claude-code-only.
          '';
        };
    };

  # Generated fields first, then the shared and per-CLI passthrough attrsets.
  skillHeader = name: d: {
    inherit name;
    inherit (d) description license;
    metadata = ai.nonEmpty d.metadata;
    disable-model-invocation = d.disableModelInvocation;
  };
  headers = {
    opencode = name: d: skillHeader name d // d.extra // d.opencode;
    claude-code =
      name: d:
      skillHeader name d
      // {
        allowed-tools = ai.nonEmpty (ai.claudeTools (ai.enabledTools d.tools));
      }
      // d.extra
      // d.claude;
  };

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

  # Ordered source list for the merged skills directory of `target`. Later
  # entries win on a name collision, so the upstream sets shadow the bundled
  # local ones (e.g. local `code-review` loses to matt-pocock's). Local skills
  # carry a generated SKILL.md; upstream ones are copied untouched.
  skillSources =
    target:
    map (
      name:
      let
        d = cfg.definitions.${name};
      in
      {
        inherit name;
        inherit (d) src;
        skillMd = pkgs.writeText "${name}-SKILL.md" (
          ai.render (headers.${target} name d) (builtins.readFile (d.src + "/SKILL.md"))
        );
      }
    ) (lib.filter (name: lib.elem target cfg.definitions.${name}.targets) cfg.local.include)
    ++ map (name: {
      inherit name;
      src = "${inputs.caveman}/skills/${name}";
    }) cfg.caveman.include
    ++
      map
        (name: {
          inherit name;
          src = mattPocockSkills.${name};
        })
        (
          if cfg.matt-pocock.include == [ ] then lib.attrNames mattPocockSkills else cfg.matt-pocock.include
        );

  # Both CLIs only scan `skills/<name>/SKILL.md`, so the whole set has to land
  # in one directory per CLI. Built as a store path; home-manager lndir's it
  # into ~/.config/opencode/skills/ and ~/.claude/skills/ (real directories,
  # read-only per-file symlinks), which keeps runtime-added skills (astrocode
  # extraDirs, learned patterns) possible.
  skillsDir =
    target:
    pkgs.runCommandLocal "${target}-skills" { } ''
      mkdir -p $out
      ${lib.concatMapStrings (s: ''
        rm -rf "$out/${s.name}"
        cp -r --no-preserve=mode ${lib.escapeShellArg "${s.src}"} "$out/${s.name}"
        ${lib.optionalString (s ? skillMd) ''cp --no-preserve=mode ${s.skillMd} "$out/${s.name}/SKILL.md"''}
      '') (skillSources target)}
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
      definitions = mkOption {
        type = types.attrsOf (types.submodule skillModule);
        default = { };
        description = ''
          Local skill definitions; each SKILL.md gets a generated header per
          CLI. The bundled ones (skills/definitions.nix) are set with mkDefault
          per field, so a profile can override single fields or add a new
          skill with its own `src`.
        '';
      };

      # Local skill set (`definitions`). Opt-in by name.
      local = {
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of skills in `custom.ai.skill.definitions` (bundled ones:
            directories next to skills/default.nix) to deploy to opencode and
            claude-code. Empty = deploy none.
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
      custom.ai.skill.definitions = ai.mkDefaultLeaves (import ./definitions.nix);

      assertions = [
        (ai.includeAssertion "custom.ai.skill.local.include" cfg.local.include (
          lib.attrNames cfg.definitions
        ))
        (ai.includeAssertion "custom.ai.skill.caveman.include" cfg.caveman.include (
          lib.attrNames cavemanSkills
        ))
        (ai.includeAssertion "custom.ai.skill.matt-pocock.include" cfg.matt-pocock.include (
          lib.attrNames mattPocockSkills
        ))
      ];
    }

    # Declarative alternative to copying into skills/ at activation. Each CLI's
    # catalog is materialized as one store directory (see skillsDir above);
    # home-manager lndirs it into place.
    (lib.mkIf (skillSources "opencode" != [ ]) {
      programs.opencode.skills = "${skillsDir "opencode"}";
    })
    (lib.mkIf (skillSources "claude-code" != [ ]) {
      programs.claude-code.skills = "${skillsDir "claude-code"}";
    })
  ];
}
