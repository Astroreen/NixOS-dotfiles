{ pkgs, lib, ... }:
{
  services = with lib; {
    xserver.enable = true;

    libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
    };
    seatd.enable = true;

    blueman.enable = true;

    gnome = {
      gnome-settings-daemon.enable = true;
      gnome-keyring.enable = true;
    };

    gvfs.enable = true; # Enables trash
    power-profiles-daemon.enable = mkDefault true; # Enable power profiles
    upower.enable = mkDefault true; # Enable upower for battery management
  };

  security = {
    rtkit.enable = true;

    pam.services = {
      login.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };
  };

  programs.dconf.enable = true; # configuration database primarily for GNOME apps
}
