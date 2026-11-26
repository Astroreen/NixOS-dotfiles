# Light self-hosted GitHub Actions runner for Astroreen/Caspian-Logistics-ERP:
# runs only the seconds-long text/script checks (PR description & risk label,
# Pointers, Looks like, and Review norms reply). Heavy CI, e2e and AI reviews
# run on Ubicloud Managed Runners.
#
# Registration (once, and again after a change to url/labels/name, since a
# registration token is only valid for an hour):
#   gh api -X POST repos/Astroreen/Caspian-Logistics-ERP/actions/runners/registration-token \
#     --jq .token | sudo install -D -m 600 /dev/stdin /var/lib/secrets/github-runner-caspian
#   sudo systemctl restart github-runner-caspian-light-1
# A renamed or removed runner stays on GitHub as offline: delete it with
#   gh api -X DELETE repos/Astroreen/Caspian-Logistics-ERP/actions/runners/<id>
#
# Runs with DynamicUser + tmpfs workDir (no persistent caches, no Docker/Podman)
# inside caspian-ci.slice (capped by caspian.slice in ./configuration.nix so
# CI cannot starve builder agents or LAN services).
{
  config,
  pkgs,
  ...
}:
{
  services.github-runners.caspian-light-1 = {
    enable = true;
    url = "https://github.com/Astroreen/Caspian-Logistics-ERP";
    tokenFile = "/var/lib/secrets/github-runner-caspian";
    name = "${config.networking.hostName}-caspian-light-1";
    # Default labels (self-hosted, Linux, X64) are added automatically.
    extraLabels = [
      "hercules"
      "light"
    ];
    # Non-ephemeral (same as the previous runners): works with a 1-hour
    # registration token in tokenFile (ephemeral = true requires a PAT or
    # GitHub App). The repository is private so collaborators share the trust
    # boundary.
    replace = true;

    # Tools used by pr-body.yml, pointers.yml, looks-like.yml and
    # review-norms.yml (reply) beyond the module's default bash/coreutils/git.
    extraPackages = with pkgs; [
      diffutils
      findutils
      gawk
      gh
      gnugrep
      gnused
      jq
      nodejs
      perl
    ];

    serviceOverrides = {
      Slice = "caspian-ci.slice";
      InaccessiblePaths = [ "-/run/docker.sock" ];
      # Block LAN, Tailnet, Docker and link-local ranges; 127.0.0.1 stays
      # reachable for Pi-hole DNS and public IPs stay reachable for GitHub.
      IPAddressDeny = [
        "10.0.0.0/8"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "fc00::/7"
        "fe80::/10"
      ];
    };
  };

  # Memory and CPUs are capped by the parent caspian.slice (./configuration.nix).
  # Lower CPU/IO weight so builder agents win when the host is busy.
  systemd.slices.caspian-ci.sliceConfig = {
    CPUWeight = 50;
    IOWeight = 50;
  };
}
