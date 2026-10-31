_: {
  users.users.astroreen = {
    isNormalUser = true;
    description = "astroreen";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "audio"
      "input"
      "seat"
      "bluetooth"
      "docker"
      "wireshark"
      "dialout"
      "kvm"
      "libvirtd"
      "dialout"
    ];
  };

  # astroreen is the only wheel member on every host (the servers' `agent`
  # account is not in wheel), so sudo never asks: remote deploys and agents
  # in astroreen's session run root commands non-interactively.
  security.sudo.wheelNeedsPassword = false;

  nix.settings.trusted-users = [
    "root"
    "astroreen"
  ];
}
