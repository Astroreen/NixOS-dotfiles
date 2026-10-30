# Self-hosted GitHub Actions runners for Astroreen/Caspian-Logistics-ERP
# (.github/workflows/{ci,claude-review,pipeline}.yml):
#   - caspian-ci (5): backend, frontend, changesets and the Claude review;
#   - caspian-e2e (3): Playwright e2e; each job takes its ports, container
#     name and storage from the runner name (Caspian #190), so they overlap;
#   - caspian-pipeline (1): merge queue, merges with astroreen's own gh login.
#
# Registration (once, and again after a change to url/labels/name/workDir,
# since a registration token is only valid for an hour):
#   gh api -X POST repos/Astroreen/Caspian-Logistics-ERP/actions/runners/registration-token \
#     --jq .token | sudo install -D -m 600 /dev/stdin /var/lib/secrets/github-runner-caspian
#   sudo systemctl restart 'github-runner-caspian-*'
# A renamed or removed runner stays on GitHub as offline: delete it with
#   gh api -X DELETE repos/Astroreen/Caspian-Logistics-ERP/actions/runners/<id>
#
# Moved here from aktkc (2026-10-30). All runners share caspian-ci.slice,
# capped so CI cannot starve the builder agents running on the same host.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  url = "https://github.com/Astroreen/Caspian-Logistics-ERP";
  tokenFile = "/var/lib/secrets/github-runner-caspian";

  # Persistent on disk: the runner's own HOME and workDir would be the
  # runtime dir (tmpfs, wiped on every start). ~/.gradle (with the Gradle
  # build cache), ~/.npm and ~/.cache/ms-playwright are shared by all runners
  # and survive restarts; the workflows rely on that instead of cache actions.
  root = "/var/lib/caspian-ci";
  home = "${root}/home";

  # A backend gradle test takes ~3 GB; the host shares its 31 GB with up to
  # ~15 builder agents. One e2e job: ~1.5 GB backend JVM plus the Chromium
  # workers (~2 GB each), its PostgreSQL container runs outside the slices.
  ciRunners = 5;
  e2eRunners = 3;

  numbered = prefix: n: map (i: "${prefix}-${toString i}") (lib.range 1 n);

  runners =
    lib.genAttrs (numbered "caspian-ci" ciRunners) (_: {
      labels = [ "caspian-ci" ];
    })
    // lib.genAttrs (numbered "caspian-e2e" e2eRunners) (_: {
      labels = [ "caspian-e2e" ];
      slice = "caspian-ci-e2e.slice";
    })
    // {
      caspian-pipeline = {
        labels = [ "caspian-pipeline" ];
        ghLogin = true;
      };
    };
in
{
  services.github-runners = lib.mapAttrs (
    name: runner:
    let
      ghLogin = runner.ghLogin or false;
    in
    {
      enable = true;
      inherit url tokenFile;
      name = "${config.networking.hostName}-${name}";
      extraLabels = runner.labels;
      replace = true; # Re-registering under the same name replaces the old entry
      workDir = "${root}/work/${name}";

      # In the docker group: the e2e job starts its own PostgreSQL container.
      user = "astroreen";

      extraPackages = with pkgs; [
        config.virtualisation.docker.package
        gh
        jq
        curl
        diffutils
        gawk
        iproute2 # ss, used by the e2e job to stop the backend
        procps
        which
        unzip
        xz
      ];

      extraEnvironment = {
        HOME = home;
        # Java takes user.home from passwd (/home/astroreen, hidden), not HOME.
        GRADLE_USER_HOME = "${home}/.gradle";
        # setup-java, setup-node, bun (Claude review) and Playwright's Chromium
        # are prebuilt binaries; session variables do not reach systemd units.
        inherit (config.environment.sessionVariables) NIX_LD NIX_LD_LIBRARY_PATH;
      }
      // lib.optionalAttrs ghLogin {
        # The workflow empties GH_TOKEN, so gh falls back to this login.
        GH_CONFIG_DIR = "${home}/.config/gh-astroreen";
      };

      serviceOverrides = {
        Slice = runner.slice or "caspian-ci.slice";
        ReadWritePaths = [ home ];
        # Group membership (docker socket) needs the real ids. The docker group
        # gives root anyway, so the user namespace protects nothing here.
        PrivateUsers = false;
        # Removes capset from the module's deny list: Chromium's zygote cannot
        # fork without it ("GPU process isn't usable") and every e2e page dies.
        SystemCallFilter = [ "capset" ];
      }
      // lib.optionalAttrs ghLogin {
        # /home stays hidden (ProtectHome); only the gh login is mapped in.
        BindReadOnlyPaths = [ "/home/astroreen/.config/gh:${home}/.config/gh-astroreen" ];
      };
    }
  ) runners;

  # Shared limits of all runners and their jobs (docker containers excepted,
  # they run under dockerd). Over MemoryHigh the jobs are throttled and pushed
  # to zram; MemoryMax OOM-kills inside the slice, never the builders. Lower
  # CPU/IO weight: the builders win when the host is busy. The e2e runners sit
  # in the child caspian-ci-e2e.slice: within the shared cap, Chromium cannot
  # crowd out the gradle tests (and the other way round).
  systemd.slices = {
    caspian-ci.sliceConfig = {
      MemoryHigh = "20G";
      MemoryMax = "24G";
      CPUWeight = 50;
      IOWeight = 50;
    };
    caspian-ci-e2e.sliceConfig = {
      MemoryHigh = "13G";
      MemoryMax = "15G";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${root} 0750 astroreen users -"
    "d ${home} 0700 astroreen users -"
    "d ${root}/work 0750 astroreen users -"
  ]
  ++ map (name: "d ${root}/work/${name} 0700 astroreen users -") (lib.attrNames runners);

  # System libraries of Playwright's Chromium (ubuntu build), as in the repo's
  # frontend/e2e/nix-shell.nix; the rest of the list is in ../common/base/nix-ld.nix.
  programs.nix-ld.libraries = with pkgs; [
    glib
    nss
    nspr
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    libdrm
    expat
    mesa
    libgbm
    libxkbcommon
    pango
    cairo
    alsa-lib
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libXcursor
    libXi

    # Temurin's AWT (Excel export tests) and Chromium load fontconfig at runtime
    fontconfig
    freetype
  ];

  # A headless host has no system fonts; without any, AWT fails with
  # "Fontconfig head is null" and Chromium renders no text.
  fonts.packages = [ pkgs.dejavu_fonts ];
}
