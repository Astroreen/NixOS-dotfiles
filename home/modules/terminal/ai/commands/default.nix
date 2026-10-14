{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai.command;

  # Bundled slash commands: the `.md` files next to this file. Selected by name
  # through `custom.ai.command.local.include` (empty = deploy none).
  bundledDir = ./.;
  bundledCommands = builtins.removeAttrs (lib.filterAttrs (_: type: type == "regular") (
    builtins.readDir bundledDir
  )) [ "default.nix" ];

  # opencode accepts an attrset of file paths and symlinks each entry itself.
  # Real Nix paths are required: the module only resolves `lib.isPath` values to
  # a store file (a store-path string is written as inline file content), so the
  # path is built with `+` instead of string interpolation.
  commandFile = name: bundledDir + "/${name}.md";

  # claude-code only exposes a directory option, so the same selection is
  # materialized as a store directory.
  claudeCommandsDir = pkgs.runCommandLocal "claude-code-commands" { } ''
    mkdir -p $out
    ${lib.concatMapStrings (name: ''
      cp --no-preserve=mode ${lib.escapeShellArg "${bundledDir}/${name}.md"} "$out/${name}.md"
    '') cfg.local.include}
  '';
in
{
  options = with lib; {
    custom.ai.command = {
      local = {
        include = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Names of bundled slash commands to deploy to opencode and
            claude-code. Names are the `.md` files next to
            `commands/default.nix`, without the suffix (e.g. `handoff`).
            Empty = deploy none.
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    # Eval-time guard against typos in the include list (assertions stay lazy,
    # unlike a bare `assert`, which would force cfg during merging).
    {
      assertions = [
        {
          assertion = lib.all (name: builtins.hasAttr "${name}.md" bundledCommands) cfg.local.include;
          message = ''
            custom.ai.command.local.include: unknown commands: ${
              toString (lib.filter (name: !(builtins.hasAttr "${name}.md" bundledCommands)) cfg.local.include)
            }
            Available: ${toString (map (lib.removeSuffix ".md") (lib.attrNames bundledCommands))}'';
        }
      ];
    }

    (lib.mkIf (cfg.local.include != [ ]) {
      programs.opencode.commands = lib.genAttrs cfg.local.include commandFile;
      programs.claude-code.commandsDir = "${claudeCommandsDir}";
    })
  ];
}
