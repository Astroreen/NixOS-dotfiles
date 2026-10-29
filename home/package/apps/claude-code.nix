{
  claude-code,
  fetchurl,
  stdenv,
}:

# Claude Code upstream pin. Nixpkgs lags Anthropic's release cadence, and
# T3 Code's `claudeAgent` driver enforces a minimum at runtime (see its driver
# manifest: ~/.t3/userdata/model-manifest.json). As of 2026-10-14 nixpkgs
# carries 2.1.278 while T3 requires >= 2.1.280 (>= 2.1.293 for the newest
# models), so nixpkgs' copy is reported as "outdated".
#
# Instead of bumping all of nixpkgs for one patch level, re-point the nixpkgs
# derivation's version + prebuilt release binary at a newer release. The base
# package (fetchurl + unzstd + wrapper) is reused as-is via overrideAttrs.
#
# To update: the newest version is at
#   https://downloads.claude.ai/claude-code-releases/latest
# take the per-platform `checksum` (hex sha256) from
#   https://downloads.claude.ai/claude-code-releases/<version>/manifest.zst.json
# (plain JSON despite the name), convert it with
#   nix hash convert --hash-algo sha256 --to sri <checksum>
# and refresh both below.
let
  version = "2.1.312";

  # Same platform key scheme nixpkgs' claude-code/package.nix uses.
  platformKey = "${stdenv.hostPlatform.node.platform}-${stdenv.hostPlatform.node.arch}";
  checksums = {
    "linux-x64" = "sha256-b7njKZR8ADdAvoiPmNsa7KojjWx9nO74WB63HVpZSAs=";
  };

  baseUrl = "https://downloads.claude.ai/claude-code-releases";
in
claude-code.overrideAttrs (_old: {
  inherit version;
  src = fetchurl {
    url = "${baseUrl}/${version}/${platformKey}/claude.zst";
    hash = checksums.${platformKey};
  };
})
