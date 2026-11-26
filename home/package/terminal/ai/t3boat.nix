# t3boat (`t3code-boat`): MCP server and CLI bridging T3 Code's Linked
# Environments with ephemeral boat.dev sandboxes.
#
# Built declaratively from an audited upstream commit instead of running
# `npx -y t3code-boat`, preventing silent supply-chain updates while holding
# BOAT_API_KEY.
#
# Updating:
#   1. Audit the new commit in https://github.com/trevize-dev/t3boat.
#   2. Update `version`, `rev`, and `src.hash`:
#        nix hash to-sri --type sha256 "$(nix-prefetch-url --unpack https://github.com/trevize-dev/t3boat/archive/<rev>.tar.gz)"
#   3. Set `npmDepsHash = lib.fakeHash`, build, and paste the `got:` hash.
{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  nodejs_24,
}:
buildNpmPackage {
  pname = "t3code-boat";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "trevize-dev";
    repo = "t3boat";
    rev = "abc23a9553c0d20fb31983d799d5448cc63d6802";
    hash = "sha256-9SvlcjSZGpL+wqjWwIWNy2FtHMBdXaRi9Q1ntfPkb54=";
  };

  # 1. When a Boat environment pre-clones the repo on its base branch, still
  #    fetch and switch to the requested `ref` instead of staying on `main`.
  # 2. Support booting sandboxes from a saved snapshot (`from` / T3BOAT_DEFAULT_SNAPSHOT).
  patches = [
    ./t3boat-checkout-existing-ref.patch
    ./t3boat-saved-snapshot.patch
  ];

  npmDepsHash = "sha256-rfrOSYucG/4g4wmaf87hSyUGXVGxe0vwt9taFyPEd/c=";
  nodejs = nodejs_24;
  npmBuildScript = "build";

  # bin/t3boat.mjs runs raw TypeScript when src/index.ts exists next to it;
  # remove src/ from the installed package so it always executes compiled dist/.
  postInstall = ''
    rm -rf "$out/lib/node_modules/t3code-boat/src"
  '';

  meta = {
    description = "MCP server that boots boat.dev sandboxes as linked T3 Code environments";
    homepage = "https://github.com/trevize-dev/t3boat";
    license = lib.licenses.asl20;
    mainProgram = "t3boat";
  };
}
