# Google Antigravity CLI (`agy`) as an agent T3 Code can drive.
#
# T3 Code's "Antigravity" provider spawns the ACP server itself, so this is the
# CLI-only install: the IDE (`antigravity-ide`) is a desktop app and is not
# needed for a headless server. The version comes from
# overlays/antigravity-cli.nix, because T3 Code >= 0.1.10 needs `agy` 1.5.0+
# for `agy acp` and the pinned nixpkgs release (1.4.8) predates it.
#
# Pairing (Settings -> Providers -> Antigravity, provider instance in
# home/astroreen/profiles/apps/t3code/settings.json):
#   * binary path `agy` (found in ~/.nix-profile/bin via the T3 service PATH),
#     sign-in method "Google account" (oauth-personal).
#   * The provider signs in through the ACP server, which needs a browser; on a
#     headless host it answers "No browser is available here". Sign in once
#     from a terminal instead:
#         agy acp --login
#     Open the printed accounts.google.com link on a desktop, approve it, then
#     paste the authorization code (or the whole
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
  agy = (import ../../../../../overlays/antigravity-cli.nix pkgs).antigravity-cli;
in
{
  home.packages = [ agy ];
}
