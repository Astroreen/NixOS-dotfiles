{
  config,
  pkgs,
  lib,
  ...
}:
let
  # `.mcp.json` has no `disabled`/`enabled` field (Claude Code ignores them and
  # starts every listed server), so drop disabled servers here and strip the
  # HM-only keys, like HM's own `enableMcpIntegration` does.
  baseMcpServers =
    lib.mapAttrs
      (
        _: server:
        lib.hm.mcp.transformMcpServer {
          inherit server;
          exclude = [ "enabled" ];
          extraTransforms = [ lib.hm.mcp.addType ];
        }
      )
      (
        lib.filterAttrs (_: s: !(s.disabled or false) && (s.enabled or null) != false) (
          config.programs.mcp.servers or { }
        )
      );

  # Newer than nixpkgs' copy, which T3 Code's `claudeAgent` driver reports as
  # outdated (needs >= 2.1.280). Pin + update notes live in the package.
  claudeCode = pkgs.callPackage ../../../../../package/apps/claude-code.nix { };

  # Claude Code CLI reliably reads configs from files named exactly `.mcp.json`.
  mcpConfigDir = pkgs.writeTextDir ".mcp.json" (
    builtins.toJSON {
      mcpServers = baseMcpServers;
    }
  );

  claudeFixed = pkgs.writeShellScriptBin "claude" ''
    # Call the upstream launcher (sets required PATH/env).
    # --mcp-config is variadic, so we pass it as a single token with '='.
    exec -a "$0" ${claudeCode}/bin/claude \
      --mcp-config=${mcpConfigDir}/.mcp.json \
      --strict-mcp-config \
      "$@"
  '';
in
{
  imports = [
    ../../../../../modules/terminal/ai # agents/commands/skills payload + custom.ai.* options
    ../payload.nix # prompt + agents/commands/skills, shared with opencode
  ];

  programs = {
    claude-code = {
      enable = true;

      # Everything except the package comes from custom.ai.* (set in
      # ../payload.nix: `prompt` → CLAUDE.md, `agent`/`command` →
      # agents/commands, `skill` → skills).

      package = claudeFixed;
    };

    vscode.profiles.default.userSettings = {
      "claudeCode.preferredLocation" = "panel";
    };
  };
}
