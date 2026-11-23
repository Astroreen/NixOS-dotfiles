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
{ pkgs, ... }:
let
  # `nixpkgs.overlays` (overlays/default.nix -> overlays/antigravity-cli.nix)
  # only reaches the NixOS side; Home Manager's pkgs here are instantiated
  # without overlays, so the same bump is applied to this instance directly.
  # T3 Code >= 0.1.10 needs `agy` 1.5.0+ for `agy acp`; the pinned nixpkgs
  # release is 1.4.8.
  agy = (import ../../../../../../overlays/antigravity-cli.nix pkgs).antigravity-cli;
in
{
  imports = [
    ../../../../../modules/terminal/ai # prompt/agents/commands/skills payload + custom.ai.* options
    ../payload.nix # shared with opencode and claude-code
  ];

  home.packages = [ agy ];
}
