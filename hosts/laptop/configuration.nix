{ config, pkgs, ... }:

{
  imports = [
      ./hardware-configuration.nix  # Required.
      
      ../../modules/wm/hyprland     # Window managers
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.hostName = "laptop"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Vilnius";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.astroreen = {
    isNormalUser = true;
    description = "astroreen";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ru_RU.UTF-8/UTF-8" "lt_LT.UTF-8/UTF-8" ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru,lt";
    variant = ",phonetic,us";
    options = "grp:win_space_toggle,grp:alt_shift_toggle";
  };
  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # Display manager
  services.displayManager = {
    # CAUTION: DO NOT ENABLE BOTH!
    sddm.enable = false;
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
  };
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Desktop Environments
  services.desktopManager.plasma6.enable = true;
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  # System wide packages
  environment.systemPackages = with pkgs; [
    nautilus              # File manager
    kitty                 # Console
    walker                # App launcher
    hyprpaper             # Wallapaper
    seahorse              # Keyring
    nwg-look              # Theming
    hyprshot              # Screenshot
    wl-clip-persist       # Clipboard

    # System utilities
    brightnessctl         # Brightness controls
    playerctl             # Music player control
    networkmanagerapplet  # Network Manager applet
    pavucontrol
    tree                  # `tree` command

    # Others
    gnome-calculator      # Calculator
    gnome-text-editor     # Gnome text editor
    vim                   # Vim text editor
  ];
  
  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono                                                                     
    font-awesome
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Security
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  services.gvfs.enable = true; # Enables trash
  services.power-profiles-daemon.enable = true;

  # Install firefox. Default.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
