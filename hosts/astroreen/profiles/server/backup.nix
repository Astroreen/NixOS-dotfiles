_: {
  # Daily restic snapshot of user and service state. The repository location
  # and its password are not in this repo: create both files by hand on the
  # host (root-owned, mode 600). The first run initializes the repository.
  services.restic.backups.server = {
    initialize = true;
    repositoryFile = "/etc/restic/repository";
    passwordFile = "/etc/restic/password";

    paths = [
      "/home"
      "/var/lib" # Service state, including Docker named volumes
    ];

    exclude = [
      "/home/*/.cache"
      "/home/*/.local/share/containers" # Rootless podman images
      "/var/lib/docker/overlay2" # Image layers, rebuildable
      "/var/lib/docker/image"
      "/var/lib/docker/buildkit"
      "/var/lib/containers"
      "/var/lib/systemd/coredump"
      "node_modules"
    ];

    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true; # Catch up after downtime
      RandomizedDelaySec = "30m";
    };

    # Retention: after each backup `restic forget --prune` drops everything
    # outside this window and frees the space, so the repository stays bounded.
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
}
