{
  config,
  lib,
  pkgs,
  ...
}:
let
  baseMcpServers = config.programs.mcp.servers or { };

  # Claude Code CLI reliably reads configs from files named exactly `.mcp.json`.
  mcpConfigDir = pkgs.writeTextDir ".mcp.json" (
    builtins.toJSON {
      mcpServers = baseMcpServers;
    }
  );

  claudeFixed = pkgs.writeShellScriptBin "claude" ''
    # Call the upstream launcher (sets required PATH/env).
    # --mcp-config is variadic, so we pass it as a single token with '='.
    exec -a "$0" ${pkgs.claude-code}/bin/claude \
      --mcp-config=${mcpConfigDir}/.mcp.json \
      --strict-mcp-config \
      "$@"
  '';
in
{
  imports = [
    ../mcps.nix
  ];

  programs = {
    claude-code = {
      enable = true;

      memory.source = ../AGENTS.md;
      agentsDir = ../agents;
      commandsDir = ../commands;
      skillsDir = ../skills;

      package = claudeFixed;
    };

    vscode.profiles.default.userSettings = {
      "claudeCode.preferredLocation" = "panel";
    };
  };
}
