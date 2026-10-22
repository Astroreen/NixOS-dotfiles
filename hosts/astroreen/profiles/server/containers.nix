_: {
  virtualisation = {
    # Services (compose stacks, databases) run in Docker, managed by astroreen.
    docker = {
      enable = true;
      # Weekly `docker system prune`: stopped containers, dangling images,
      # unused networks and build cache. Volumes are kept.
      autoPrune.enable = true;
    };

    # Rootless containers for the agent account (no daemon, no root socket).
    podman.enable = true;
  };
}
