# Google Antigravity CLI (`agy`), bumped ahead of this flake's nixpkgs.
#
# T3 Code >= 0.1.10 drives the Antigravity agent through the CLI's `agy acp`
# subcommand and marks every release below 1.5.0 "broken" (the CLI only serves
# ACP itself from 1.5.0 on). The pinned nixpkgs still carries 1.4.8, so the
# provider cannot use it; 1.5.13 is the version nixpkgs master ships and the
# one T3 Code recommends (>= 1.5.12 < 2). Drop this overlay once the flake's
# nixpkgs reaches 1.5.13.
prev:
let
  version = "1.5.13";
  buildId = "5999302598852608";
  wholeVersion = "${version}-${buildId}";

  # Same asset URLs and hashes as pkgs/by-name/an/antigravity-cli in nixpkgs
  # master; the derivation installs the binary as `agy`.
  sources = {
    x86_64-linux = {
      path = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-f6nMbfDQlWJpPWN8QGqGwbD1KrM2RxSx/S15zGBg1LI=";
    };
    aarch64-linux = {
      path = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-Nllq2AOFMf118Ol7W6iWejDy/Wf42cYZWdLkdh17IV8=";
    };
    aarch64-darwin = {
      path = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-HIPj6Ii1QQxEptilRn9+yg11xNVVHIAHa32o3Hc4vZw=";
    };
  };

  system = prev.stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "antigravity-cli ${version} is not packaged for ${system}");
in
{
  antigravity-cli = prev.antigravity-cli.overrideAttrs (old: {
    inherit version;

    src = prev.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/${source.path}";
      hash = source.hash;
    };

    # `wholeVersion` feeds upstream's updateScript, which this overlay replaces.
    passthru = (old.passthru or { }) // {
      inherit wholeVersion;
      updateScript = null;
    };
  });
}
