# Headless home base shared by every host (desktop and server).
_: {
  imports = [
    # Terminal apps (tui)
    ../../profiles/terminal/shell # Shell settings
    ../../profiles/terminal/devenv.nix # DevEnv for project scripts
    ../../profiles/terminal/ranger.nix # Terminal file manager
    ../../profiles/terminal/nix-gc.nix # Expire old user profile generations
    ../../profiles/terminal/ai/opencode # Open Code
    ../../profiles/terminal/ai/claude # Claude Code
    ../../profiles/terminal/ai/antigravity # Google Antigravity CLI (agy)
    ../../profiles/terminal/ai/codex # OpenAI Codex CLI
    ../../profiles/terminal/ai/cliproxyapi.nix # Route CLIs through hercules's CLIProxyAPI
    ../../profiles/terminal/ai/boat.nix # boat.dev CLI + t3boat MCP bridge

    # Languages
    ../../profiles/lang/javascript.nix
    ../../profiles/lang/python.nix
  ];
}
