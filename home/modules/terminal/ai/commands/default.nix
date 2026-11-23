{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai.command;
  ai = import ../lib.nix { inherit lib pkgs; };

  # Bundled slash commands: frontmatter-free `<name>.md` bodies next to this
  # file, with their metadata in definitions.nix. The header of each CLI is
  # generated from `custom.ai.command.definitions.<name>`.
  bundledDir = ./.;

  commandModule =
    { name, ... }:
    {
      options =
        with lib;
        {
          body = mkOption (
            {
              type = types.either types.path types.lines;
              description = "Command template (Markdown body without frontmatter, `$ARGUMENTS` works in both CLIs), as a file or inline text.";
            }
            // ai.optionalDefault (bundledDir + "/${name}.md")
          );

          agent = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Agent that runs the command. opencode always honors it; claude-code
              only when `subtask = true` (rendered as `context: fork` + `agent`).
            '';
          };

          subtask = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = "Run the command as a subagent task instead of in the current session.";
          };

          argumentHint = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "[file] [focus]";
            description = "Argument hint shown in autocomplete (claude-code `argument-hint`; opencode has none).";
          };
        }
        // ai.commonOptions {
          toolsDescription = ''
            Enabled entries become claude-code `allowed-tools` (used without a
            permission prompt while the command runs). opencode commands have no
            tool setting, so it is claude-code-only.
          '';
        };
    };

  # Generated fields first, then the shared and per-CLI passthrough attrsets.
  opencodeHeader =
    _: d:
    {
      inherit (d) description agent subtask;
    }
    // d.extra
    // d.opencode;

  claudeHeader =
    _: d:
    let
      forked = d.subtask == true && d.agent != null;
    in
    {
      inherit (d) description;
      argument-hint = d.argumentHint;
      allowed-tools = ai.nonEmpty (ai.claudeTools (ai.enabledTools d.tools));
      context = if forked then "fork" else null;
      agent = if forked then d.agent else null;
    }
    // d.extra
    // d.claude;

  renderFor = ai.renderIncluded cfg.definitions cfg.local.include;

  # Antigravity has no file-based slash commands: its own importer turns command
  # files into skills, so each command lands as
  # ~/.gemini/config/skills/<name>/SKILL.md with `$ARGUMENTS` explained in the
  # body (see ai.antigravityCommandBody). A command whose name matches a skill
  # would collide in that directory — keep the two lists disjoint.
  antigravityHeader =
    name: d:
    {
      inherit name;
      inherit (d) description;
    }
    // d.extra
    // d.antigravity;

  antigravityCommands = lib.mapAttrs (
    name: d:
    pkgs.writeTextDir "SKILL.md" (
      ai.render (antigravityHeader name d) (
        ai.antigravityCommandBody (if lib.isPath d.body then builtins.readFile d.body else d.body)
      )
    )
  ) (ai.includedFor cfg.definitions cfg.local.include "antigravity");
in
{
  options = with lib; {
    custom.ai.command = {
      definitions = mkOption {
        type = types.attrsOf (types.submodule commandModule);
        default = { };
        description = ''
          Slash command definitions, rendered into opencode and claude-code command
          files, and as skills for Antigravity (which has no file-based commands). The bundled ones (commands/definitions.nix) are set
          with mkDefault per field, so a profile can override single fields or
          add a new command with its own `body`.
        '';
      };

      local = {
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of commands in `custom.ai.command.definitions` to deploy to
            opencode, claude-code and Antigravity (bundled ones: the `.md` files next to
            `commands/default.nix`, without the suffix, e.g. `handoff`).
            Empty = deploy none.
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    {
      custom.ai.command.definitions = ai.mkDefaultLeaves (import ./definitions.nix);

      assertions = [
        (ai.includeAssertion "custom.ai.command.local.include" cfg.local.include (
          lib.attrNames cfg.definitions
        ))
      ];
    }

    (lib.mkIf (cfg.local.include != [ ]) {
      programs.opencode.commands = renderFor "opencode" opencodeHeader;
      programs.claude-code.commands = renderFor "claude-code" claudeHeader;
    })

    # Antigravity slash commands are skills; real files, see ai.antigravitySync.
    (lib.mkIf (antigravityCommands != { }) {
      home.activation.antigravityCommands = ai.antigravitySync {
        name = "commands";
        dir = ".gemini/config/skills";
        files = antigravityCommands;
      };
    })
  ];
}
