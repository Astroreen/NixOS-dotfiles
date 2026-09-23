{ pkgs, ... }: {
  # trayscale only creates a systemd unit via services.trayscale, which does NOT
  # put the package in the profile. Its icon (dev.deedles.Trayscale) then can't be
  # resolved by the shell (caelestia/Quickshell iconPath) for tray notifications.
  home.packages = [ pkgs.trayscale ];

  services = {
    tailscale-systray.enable = false; # Official Tailscale systray application for Linux
    trayscale.enable = true; # Unofficial Tailscale client for Linux
  };
}
