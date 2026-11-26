# Google Antigravity CLI (`agy`): a T3 Code agent (provider in
# home/astroreen/profiles/apps/t3code/settings.json) and a standalone TUI agent.
# Every host gets it, next to opencode and claude-code in
# home/astroreen/common/base/default.nix.
#
# Global prompt, skills, slash commands and custom agents come from the shared
# payload (home/astroreen/profiles/terminal/ai/payload.nix):
#   * prompt   -> ~/.gemini/GEMINI.md (store symlink; `agy` follows symlinks
#                 for global rules, both standalone and under T3 Code)
#   * skills   -> ~/.gemini/config/skills/<name>/SKILL.md (T3 Code also reads
#                 this directory directly in discoverAntigravitySkills and
#                 symlinks it into its private GEMINI_HOME)
#   * commands -> ~/.gemini/config/skills/<name>/SKILL.md (Antigravity has no
#                 file-based commands; its own importer turns them into skills)
#   * agents   -> ~/.gemini/config/agents/<name>.md
# `agy` writes new skills and agents there itself, so these are real files
# tracked in .nix-managed-<kind>, not store symlinks.
#
# Pairing with T3 Code (Settings -> Providers -> Antigravity; binary path `agy`,
# sign-in method "Google account"):
#   * The provider signs in through the ACP server, which opens a browser. On a
#     desktop that is the whole story. On a headless host it answers "No browser
#     is available here"; sign in once from a terminal instead:
#         agy acp --login
#     Open the printed accounts.google.com link anywhere, approve it, then paste
#     the authorization code (or the whole
#     https://antigravity.google/oauth-callback?... URL it lands on) back into
#     the prompt. Credentials land in ~/.gemini/antigravity-cli, the same store
#     T3's `agy acp` reads, so the provider turns ready on its next probe.
#   * Alternative without OAuth: sign-in method "Gemini API key" with a Gemini
#     (or Vertex AI express) key, which the provider passes as GEMINI_API_KEY.
#
# Note: Antigravity usage limits stay hidden in T3, which reads the managed
# runtime's profile token (<state>/providers/antigravity/<id>/antigravity-acp/
# acp_token.json) while the CLI keeps its own under ~/.gemini. Sessions and
# models work regardless.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Default model for `agy` and T3 Code's Antigravity provider. agy matches the
  # model by its label (`agy models`, right column), not by the slug.
  model = "Gemini 4 Neon (High)";

  # `nixpkgs.overlays` (overlays/default.nix -> overlays/antigravity-cli.nix)
  # only reaches the NixOS side; Home Manager's pkgs here are instantiated
  # without overlays, so the same bump is applied to this instance directly.
  # T3 Code >= 0.1.10 needs `agy` 1.5.0+ for `agy acp`; the pinned nixpkgs
  # release is 1.4.8.
  agy = (import ../../../../../../overlays/antigravity-cli.nix pkgs).antigravity-cli;

  t3StateDir = config.custom.t3code.stateDir or "${config.home.homeDirectory}/.t3/userdata";

  # Explicit T3 Code Antigravity provider instance IDs that should receive MCP
  # servers. T3 computes each profile directory as sha256(instanceId) and
  # disables Antigravity text generation on any profile with a non-empty
  # mcp_config.json, so we only target the interactive chat instance declared
  # in home/astroreen/profiles/apps/t3code/settings.json (text generation uses
  # Codex) and pre-populate it before T3's first run.
  t3AntigravityInstances = [ "antigravity" ];
  t3AntigravityConfigDirs = map (
    id: "${t3StateDir}/providers/antigravity/${builtins.hashString "sha256" id}/config"
  ) t3AntigravityInstances;

  enabledMcpServers = lib.filterAttrs (_: s: !(s.disabled or false) && (s.enabled or null) != false) (
    config.programs.mcp.servers or { }
  );

  # Antigravity stores MCP servers in <GEMINI_HOME>/config/mcp_config.json and
  # uses `serverUrl` (not `url`) for HTTP servers. Wrap `env.<KEY>.file` refs
  # with HM's helper so secrets are read at launch instead of serialized as objects.
  agyMcpPayload = pkgs.writeText "antigravity-mcp-servers.json" (
    builtins.toJSON (
      lib.mapAttrs (
        name: rawServer:
        let
          s = lib.hm.mcp.wrapEnvFilesCommand {
            inherit pkgs name;
          } rawServer;
        in
        if (s.url or null) != null then
          {
            disabled = false;
            serverUrl = s.url;
          }
          // lib.optionalAttrs ((s.headers or { }) != { }) {
            inherit (s) headers;
          }
        else
          {
            disabled = false;
            inherit (s) command;
          }
          // lib.optionalAttrs ((s.args or [ ]) != [ ]) {
            inherit (s) args;
          }
          // lib.optionalAttrs ((s.env or { }) != { }) {
            inherit (s) env;
          }
      ) enabledMcpServers
    )
  );

  python = lib.getExe pkgs.python3;
in
{
  imports = [
    ../../../../../modules/terminal/ai # prompt/agents/commands/skills payload + custom.ai.* options
    ../payload.nix # shared with opencode, claude-code and Antigravity
  ];

  home.packages = [ agy ];

  home.activation = {
    # agy writes its own settings.json, so only the `model` key is merged in.
    antigravityDefaultModel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.gemini/antigravity-cli/settings.json"
      mkdir -p "$(dirname "$cfg")"
      [ -s "$cfg" ] || echo '{}' > "$cfg"
      ${lib.getExe pkgs.jq} --arg m ${lib.escapeShellArg model} '.model = $m' "$cfg" > "$cfg.tmp"
      mv "$cfg.tmp" "$cfg"
    '';

    # Sync enabled `programs.mcp.servers` into standalone ~/.gemini/config and
    # the explicitly selected T3 Code Antigravity provider profile(s)
    # (pre-created by deterministic sha256(instanceId) so fresh hosts have MCP
    # ready on first launch without touching unrelated profiles).
    antigravityMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      (
        umask 077
        ${python} ${./sync-mcp-json.py} "$HOME/.gemini/config" ${agyMcpPayload}
        ${lib.concatMapStringsSep "\n        " (
          dir: "${python} ${./sync-mcp-json.py} ${lib.escapeShellArg dir} ${agyMcpPayload}"
        ) t3AntigravityConfigDirs}
      )
    '';
  };
}
