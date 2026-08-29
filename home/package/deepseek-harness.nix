{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  nodejs_22,
}:

let
  version = "0.1.1-rc.2";

  # Upstream publishes @deepseek-ai/dsh as a pure-ESM CLI whose ~60 scoped
  # @deepseek-ai/dsh-* dependencies all resolve from the public npm registry
  # (no workspace: protocol), so a plain buildNpmPackage resolution works.
  npmTarball = fetchurl {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${version}.tgz";
    # SRI hash taken directly from the npm registry dist.integrity field.
    hash = "sha512-UP1UIh6q3Gme/yXRn/QL2P8IsVlv8Shpg22TRJIZPsCRWLm4CBiA1MUvXmJAfsOEETBMLAl+xWPtFw6ICsN3wg==";
  };
in

buildNpmPackage {
  pname = "deepseek-harness";
  inherit version;

  # The published tarball ships no package-lock.json, so we vendor one that was
  # generated with `npm install --package-lock-only` and splice it in.
  src = runCommand "deepseek-harness-src-${version}" { } ''
    mkdir -p $out
    tar xf ${npmTarball} --strip-components=1 -C $out
    cp ${./deepseek-harness-package-lock.json} $out/package-lock.json
  '';

  npmDepsHash = "sha256-ylsDJL2aEHDKZDV3dRCforOgZGH4xx33SkeWLz86TT4=";

  # dsh requires Node.js ^22.19.0 || >=24.0.0; pin the build+runtime interpreter.
  nodejs = nodejs_22;

  # Pure-ESM package with no build step (package.json declares no scripts).
  dontNpmBuild = true;

  meta = {
    description = "DeepSeek Harness (dsh): DeepSeek AI open-source coding-agent CLI and web UI server";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.linux;
  };
}
