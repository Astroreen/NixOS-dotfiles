# Boat CLI (`boat.dev`): static ELF binary for managing Boat cloud sandboxes.
#
# Upstream distributes the CLI from a floating `channel=prod` endpoint with a
# companion SHA256SUMS file (no versioned GitHub release tags yet).
#
# Updating to a newer release:
#   1. Fetch checksums:
#        curl -fsSL "https://boat.dev/api/boat/cli/download?platform=linux-x64&channel=prod&integrity=sha256"
#   2. Convert the `boat-linux-x64` / `boat-linux-arm64` hex digests to SRI:
#        nix hash to-sri --type sha256 <hex>
#   3. Check the new version string on the binary (`./boat --version`) and
#      update `version` and `sources` below.
{
  fetchurl,
  lib,
  stdenvNoCC,
}:
let
  version = "1.0.105";

  sources = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-ny+1UprXyljk1yS7a/zW/5TLMHenwSoJQeUBqg6TNew=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-OMJQ6oMjfEg2NnaE/fr1+OfeLOwV1QtKb+rmrbhj76c=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "boat-cli ${version} is not packaged for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "boat-cli";
  inherit version;

  src = fetchurl {
    url = "https://boat.dev/api/boat/cli/download?platform=${source.platform}&channel=prod";
    name = "boat-${version}-${source.platform}";
    inherit (source) hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/boat"
    runHook postInstall
  '';

  meta = {
    description = "CLI for boat.dev persistent Ubuntu cloud sandboxes";
    homepage = "https://boat.dev";
    mainProgram = "boat";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
