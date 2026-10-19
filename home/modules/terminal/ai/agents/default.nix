{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ai.agent;
  ai = import ../lib.nix { inherit lib; };

  # Bundled agents: frontmatter-free `<name>.md` bodies next to this file, with
  # their metadata in definitions.nix. The header of each CLI is generated from
  # `custom.ai.agent.definitions.<name>`.
  bundledDir = ./.;

  agentModule =
    { name, ... }:
    {
      options =
        with lib;
        {
          body = mkOption (
            {
              type = types.either types.path types.lines;
              description = "Agent prompt (Markdown body without frontmatter), as a file or inline text.";
            }
            // ai.optionalDefault (bundledDir + "/${name}.md")
          );

          mode = mkOption {
            type = types.nullOr (
              types.enum [
                "primary"
                "subagent"
                "all"
              ]
            );
            default = null;
            description = "opencode agent mode. claude-code agents are always subagents, so it is opencode-only.";
          };

          temperature = mkOption {
            type = types.nullOr types.number;
            default = null;
            description = "Sampling temperature. opencode-only: claude-code agents have no temperature setting.";
          };

          color = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "#3498DB";
            description = ''
              Hex color. opencode gets it as is; claude-code gets the nearest of
              its named colors (override with `claude.color`).
            '';
          };
        }
        // ai.commonOptions {
          toolsDescription = ''
            opencode receives the map as `tools`; for claude-code the disabled
            entries become `disallowedTools` (unlisted tools stay available in
            both). For a claude-code allowlist set `claude.tools`.
          '';
        };
    };

  # Generated fields first, then the shared and per-CLI passthrough attrsets.
  opencodeHeader =
    _: d:
    {
      inherit (d)
        description
        mode
        temperature
        color
        ;
      tools = ai.nonEmpty d.tools;
    }
    // d.extra
    // d.opencode;

  claudeHeader =
    name: d:
    {
      inherit name;
      inherit (d) description;
      color = ai.claudeColor d.color;
      disallowedTools = ai.nonEmpty (
        lib.concatStringsSep ", " (ai.claudeTools (ai.disabledTools d.tools))
      );
    }
    // d.extra
    // d.claude;

  renderFor = ai.renderIncluded cfg.definitions cfg.local.include;
in
{
  options = with lib; {
    custom.ai.agent = {
      definitions = mkOption {
        type = types.attrsOf (types.submodule agentModule);
        default = { };
        description = ''
          Agent definitions, rendered into opencode and claude-code agent files.
          The bundled ones (agents/definitions.nix) are set with mkDefault per
          field, so a profile can tweak e.g.
          `custom.ai.agent.definitions.atlas.temperature` or add a new agent
          with its own `body`.
        '';
      };

      local = {
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of agents in `custom.ai.agent.definitions` to deploy to
            opencode and claude-code (bundled ones: the `.md` files next to
            `agents/default.nix`, without the suffix, e.g. `atlas`).
            Empty = deploy none.
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      custom.ai.agent.definitions = ai.mkDefaultLeaves (import ./definitions.nix);

      assertions = [
        (ai.includeAssertion "custom.ai.agent.local.include" cfg.local.include (
          lib.attrNames cfg.definitions
        ))
      ];
    }

    (lib.mkIf (cfg.local.include != [ ]) {
      programs.opencode.agents = renderFor "opencode" opencodeHeader;
      programs.claude-code.agents = renderFor "claude-code" claudeHeader;
    })
  ];
}
