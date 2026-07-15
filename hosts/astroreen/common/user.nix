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

  nix.settings.trusted-users = [
    "root"
    "astroreen"
  ];
}
