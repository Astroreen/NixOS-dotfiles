# Self-hosted GitHub Actions runners for Astroreen/Caspian-Logistics-ERP
# (.github/workflows/{ci,claude-review}.yml):
#   - caspian-ci (3): backend, frontend, changesets and the Claude review;
#   - caspian-e2e (3): Playwright e2e (2 workers); each job takes its ports,
#     container name and storage from the runner name (Caspian #190, #192),
#     so they run side by side.
# The caspian-pipeline runner (merge queue, pipeline.yml) is gone: the
# Pipeline workflow was switched off on 2026-11-07.
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

  # Each class has its own persistent caches and fresh work directories.
  ciUser = "caspian-ci";
  e2eUser = "caspian-e2e";
  reviewUser = "caspian-codex";
  statePath = user: "/var/lib/${user}-runner";
  reviewHome = statePath reviewUser;
  workRoot = "/var/lib/caspian-runner-work";
  # The existing workflow uses docker rm/run/exec and host networking.
  # Containers inherit the runner's cgroup. Podman needs no cgroup delegation.
  podmanDocker = pkgs.writeShellScriptBin "docker" ''
    export PATH="/run/wrappers/bin:$PATH"
    if [[ "''${1:-}" == run ]]; then
      shift
      exec ${pkgs.podman}/bin/podman --cgroup-manager=cgroupfs run --cgroups=disabled "$@"
    fi
    exec ${pkgs.podman}/bin/podman --cgroup-manager=cgroupfs "$@"
  '';
  codexReview = pkgs.writeShellScriptBin "caspian-codex-review" ''
    umask 077
    unset OPENAI_API_KEY CODEX_API_KEY OPENAI_IDENTITY_TOKEN_FILE OPENAI_TOKEN_AUDIENCE
    export CODEX_HOME=${reviewHome}/.codex
    exec ${lib.getExe pkgs.codex} -a never exec --sandbox read-only --skip-git-repo-check \
      -m gpt-6.2-sol -c model_reasoning_effort=high \
      -c forced_login_method=chatgpt -c cli_auth_credentials_store=file \
      --disable shell_tool --disable unified_exec -
  '';

  # A backend gradle test takes ~3 GB; one e2e job ~5 GB at 2 workers.
  # e2e is the slowest step of a PR, so it keeps 3 runners. The counts fit the 15G cap of caspian.slice (./configuration.nix: CI and the builder agents
  # stay under ~82% CPU, so the host keeps serving the LAN).
  ciRunners = 3;
  e2eRunners = 3;

  numbered = prefix: n: map (i: "${prefix}-${toString i}") (lib.range 1 n);

  runners =
    lib.genAttrs (numbered "caspian-ci" ciRunners) (_: {
      labels = [ "caspian-ci" ];
      user = ciUser;
    })
    // lib.genAttrs (numbered "caspian-e2e" e2eRunners) (_: {
      labels = [ "caspian-e2e" ];
      user = e2eUser;
      slice = "caspian-ci-e2e.slice";
    });
in
{
  users.groups = lib.genAttrs [ ciUser e2eUser reviewUser ] (_: { });
  users.users = lib.genAttrs [ ciUser e2eUser reviewUser ] (user: {
    isSystemUser = true;
    group = user;
    home = statePath user;
    autoSubUidGidRange = user == e2eUser;
  });

  # Device login on the trusted host after isolating and validating CI:
  #   sudo -u caspian-codex -H env CODEX_HOME=/var/lib/caspian-codex-runner/.codex \
  #     sh -c 'umask 077; exec codex login --device-auth -c cli_auth_credentials_store=file'
  # Keep this account off GitHub Actions until only a trusted workflow can
  # target it. A repository runner label alone is not an access restriction.
  # Manual review: sudo -u caspian-codex -H caspian-codex-review < review-input.txt
  environment.systemPackages = [
    codexReview
    pkgs.codex
  ];

  services.github-runners = lib.mapAttrs (
    name: runner:
    let
      home = statePath runner.user;
      isE2e = runner.user == e2eUser;
    in
    {
      enable = true;
      inherit url tokenFile;
      name = "${config.networking.hostName}-${name}";
      extraLabels = runner.labels;
      replace = true; # Re-registering under the same name replaces the old entry
      # GitHub's module cleans this path as root. Its parent must be root-owned
      # so a runner cannot replace the workdir with a symlink.
      workDir = "${workRoot}/${name}";
      inherit (runner) user;

      extraPackages =
        with pkgs;
        [
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
        ]
        ++ lib.optionals isE2e [
          podmanDocker
          pkgs.podman
        ];

      extraEnvironment = {
        HOME = home;
        # Keep Gradle on the persistent runner volume.
        GRADLE_USER_HOME = "${home}/.gradle";
        # setup-java, setup-node, bun (Claude review) and Playwright's Chromium
        # are prebuilt binaries; session variables do not reach systemd units.
        inherit (config.environment.sessionVariables) NIX_LD NIX_LD_LIBRARY_PATH;
      }
      // lib.optionalAttrs isE2e {
        XDG_RUNTIME_DIR = "/run/${name}-podman";
        XDG_DATA_HOME = "${home}/data/${name}";
      };

      serviceOverrides = {
        Slice = runner.slice or "caspian-ci.slice";
        ReadWritePaths = [ home ] ++ lib.optional isE2e "/run/${name}-podman";
        InaccessiblePaths = [
          "-/run/docker.sock"
          reviewHome
        ];
        # Rootless Podman must create a nested namespace and use newuidmap/newgidmap.
        PrivateUsers = false;

        # Removes capset from the module's deny list: Chromium's zygote cannot
        # fork without it ("GPU process isn't usable") and every e2e page dies.
        SystemCallFilter = [ "capset" ];
      }
      // lib.optionalAttrs isE2e {
        NoNewPrivileges = false;
        RestrictSUIDSGID = false;
        RestrictNamespaces = false;
        PrivateDevices = false;
        ProtectHostname = "private";
        # Masked /proc submounts prevent the rootless OCI runtime from mounting procfs.
        ProtectKernelTunables = false;
        ProtectKernelLogs = false;
        CapabilityBoundingSet = lib.mkForce [ "CAP_SETUID CAP_SETGID CAP_SETPCAP" ];
        SystemCallFilter = lib.mkForce [ "~@clock @module @raw-io @reboot" ];
      };
    }
  ) runners;

  # Shared limits of all runners and their jobs. Over MemoryHigh the jobs are throttled and pushed
  # to zram; MemoryMax OOM-kills inside the slice, never the builders. Lower
  # CPU/IO weight: the builders win when the host is busy. The e2e runners sit
  # in the child caspian-ci-e2e.slice: within the shared cap, Chromium cannot
  # crowd out the gradle tests (and the other way round).
  systemd.slices = {
    caspian-ci.sliceConfig = {
      # Memory and CPUs: capped by the parent caspian.slice (configuration.nix).
      CPUWeight = 50;
      IOWeight = 50;
    };
    caspian-ci-e2e.sliceConfig = {
      MemoryHigh = "12G"; # 3 jobs x ~5 GB at 2 workers; over it they slow down
      MemoryMax = "13G";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${workRoot} 0755 root root -"
    "d ${statePath ciUser} 0700 ${ciUser} ${ciUser} -"
    "d ${statePath e2eUser} 0700 ${e2eUser} ${e2eUser} -"
    "d ${reviewHome} 0700 ${reviewUser} ${reviewUser} -"
    "d ${reviewHome}/.codex 0700 ${reviewUser} ${reviewUser} -"
  ]
  ++ map (name: "d /run/${name}-podman 0700 ${e2eUser} ${e2eUser} -") (
    numbered "caspian-e2e" e2eRunners
  )
  ++ lib.mapAttrsToList (
    name: runner: "d ${workRoot}/${name} 0700 ${runner.user} ${runner.user} -"
  ) runners;

  virtualisation.containers.registries.settings.aliases.postgres = "docker.io/library/postgres";

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
