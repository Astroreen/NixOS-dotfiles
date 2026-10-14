{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ai.prompt;
  skillCfg = config.custom.ai.skill;

  # `custom.ai.prompt` is either inline text or a path to a file (the profile
  # passes ../CustomPrompt.md, so the text lives in the repo, not in Nix).
  baseContext = if lib.isPath cfg then builtins.readFile cfg else cfg;

  # Caveman's "always on" mode works by appending its snippet to the global
  # prompt. Done here (instead of appending at activation) so the generated
  # file can stay a plain store symlink.
  context =
    baseContext
    + lib.optionalString (
      skillCfg.caveman.enable && skillCfg.caveman.alwaysOn
    ) "\n${skillCfg.caveman.alwaysOnSnippet}";
in
{
  imports = [
    ./mcps.nix
    ./agents
    ./commands
    ./skills
    ./meridian.nix
  ];

  options = with lib; {
    # The prompt is the one piece of config that is not per-CLI: opencode and
    # claude-code read the same text (AGENTS.md / CLAUDE.md), so it is declared
    # here instead of in either program's profile.
    custom.ai.prompt = mkOption {
      type = types.either types.lines types.path;
      default = "";
      description = ''
        Global prompt for the AI CLIs, deployed as the opencode `AGENTS.md` and
        the claude-code `CLAUDE.md`. Either inline text or a path to a file
        (e.g. `../CustomPrompt.md`). Empty = deploy nothing.

        When `custom.ai.skill.caveman.alwaysOn` is enabled, its snippet is
        appended to the text.
      '';
    };
  };

  config = lib.mkIf (cfg != "") {
    programs.opencode.context = context;
    programs.claude-code.context = context;
  };
}
