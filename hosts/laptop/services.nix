{ pkgs, ... }:
{
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru,lt";
    variant = ",phonetic,us";
    options = "grp:alt_shift_toggle";
  };
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };
  services.seatd.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  services.blueman.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Display manager
  services.displayManager = {
    # CAUTION: DO NOT ENABLE BOTH!
    sddm = {
      enable = false;
      wayland.enable = true;
      autoNumlock = true;
    };
    gdm = {
      enable = false;
      wayland = true;
    };

    # Enable automatic login for the user.
    autoLogin = {
      enable = true;
      user = "astroreen";
    };

    # Defaul session to log in to. Perfect with auto login :)
    defaultSession = "hyprland";
  };
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "astroreen";
      };
    };
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Desktop Environments
  services.desktopManager.plasma6.enable = false;

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      foo2zjs
    ];
  };
  # Security
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  services.gvfs.enable = true; # Enables trash
  services.power-profiles-daemon.enable = true; # Enable power profiles
}
