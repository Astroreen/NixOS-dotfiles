# Headless home base shared by every host (desktop and server).
_: {
  imports = [
    # Terminal apps (tui)
    ../profiles/terminal/shell # Shell settings
    ../profiles/terminal/devenv.nix # DevEnv for project scripts
    ../profiles/terminal/ranger.nix # Terminal file manager
    ../profiles/terminal/ai/opencode # Open Code
    ../profiles/terminal/ai/claude # Claude Code

    # Languages
    ../profiles/lang/javascript.nix
    ../profiles/lang/python.nix
  ];
}
