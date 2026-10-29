_: {
  custom.services.n8n = {
    enable = true;
    # Pinned: n8n migrates its database on upgrade and cannot go back.
    image = "docker.io/n8nio/n8n:2.21.7";
    host = "n8n.thalamus.space";
  };
}
