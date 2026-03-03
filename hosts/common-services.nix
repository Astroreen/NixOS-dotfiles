{ pkgs, lib, ... }:
with lib;
{
  services = {
    # Configure keymap in X11
    xserver = {
      enable = true;
      xkb = {
        layout = "us,ru,lt";
        variant = ",phonetic,us";
        options = "grp:alt_shift_toggle";
      };
      videoDrivers = [ "nvidia" ];
    };
    libinput = {
      enable = true;
      touchpad.naturalScrolling = true;
    };
    seatd.enable = true;

    blueman.enable = true;

    # Audio
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Display managers
    displayManager = {
      # CAUTION: DO NOT ENABLE BOTH!
      sddm = {
        enable = false;
        wayland.enable = true;
        autoNumlock = true;
      };
      gdm = {
        enable = true;
        wayland = true;
      };

      # Enable automatic login for the user.
      autoLogin = {
        enable = true;
        user = "astroreen";
      };

      # Defaul session to log in to. Perfect with auto login :)
      defaultSession = "hyprland";

      # Wrapper for Hyprland
      # since the official DE won't rename the required option to work properly
      # sessionPackages = [
      #   (pkgs.stdenv.mkDerivation {
      #     name = "hyprland-session";
      #     src = null;
      #     dontUnpack = true;
      #     installPhase = ''
      #       mkdir -p $out/share/wayland-sessions
      #       cat > $out/share/wayland-sessions/hyprland.desktop <<EOF
      #       [Desktop Entry]
      #       Name=Hyprland
      #       Exec=/home/astroreen/.local/share/nixos/scripts/hyprland-wrapper
      #       Type=Application
      #       EOF
      #     '';
      #     passthru.providedSessions = [ "hyprland" ];
      #   })
      # ];
    };
    greetd = {
      enable = false;
      settings = {
        default_session = {
          command = "Hyprland";
          user = "astroreen";
        };
      };
    };

    gnome = {
      gnome-settings-daemon.enable = true;
      gnome-keyring.enable = true;
    };

    desktopManager.plasma6.enable = false;

    printing = {
      enable = true;
      drivers = with pkgs; [
        foo2zjs
      ];
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
