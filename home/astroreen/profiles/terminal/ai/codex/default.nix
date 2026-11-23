# OpenAI Codex CLI (`codex`): a T3 Code agent (provider in
# home/astroreen/profiles/apps/t3code/settings.json) and a standalone TUI agent.
# Every host gets it, next to opencode, claude-code and Antigravity in
# home/astroreen/common/base/default.nix.
#
# Global prompt, skills, slash commands and custom agents come from the shared
# payload (home/astroreen/profiles/terminal/ai/payload.nix):
#   * prompt   -> ~/.codex/AGENTS.md (store symlink; `codex` follows symlinks
#                 for global rules, both standalone and under T3 Code)
#   * skills   -> ~/.agents/skills/<name>/SKILL.md (real files via activation;
#                 Codex skips SKILL.md links into /nix/store)
#   * commands -> ~/.agents/skills/<name>/SKILL.md (Codex has no file-based
#                 commands, so commands ship as skills under their own
#                 .nix-managed-commands manifest)
#   * agents   -> ~/.codex/agents/<name>.toml (store symlinks; Codex loads
#                 symlinked TOML roles directly)
#
# Pairing with T3 Code (Settings -> Providers -> Codex; binary path `codex`):
#   * `pkgs.codex` comes from overlays/cli-versions.nix for both HM and NixOS;
#     it satisfies T3 Code's recommended range, and
#     home/package/apps/t3code/default.nix wraps the same derivation on `t3`'s
#     PATH (`enableCodex = true`). Installing it here also puts `codex` on the
#     user's PATH for CLI sign-in and standalone sessions.
#   * Desktop: sign in from T3 Code (Settings -> Providers -> Codex) or run
#     `codex login` (browser OAuth; credentials land in ~/.codex/auth.json).
#   * Headless host: run `codex login --device-auth`, or pass an API key with
#     `printenv OPENAI_API_KEY | codex login --with-api-key`.
{ pkgs, ... }:
{
  imports = [
    ../../../../../modules/terminal/ai # prompt/agents/commands/skills payload + custom.ai.* options
    ../payload.nix # shared with opencode, claude-code and Antigravity
  ];

  home.packages = [ pkgs.codex ];
}
