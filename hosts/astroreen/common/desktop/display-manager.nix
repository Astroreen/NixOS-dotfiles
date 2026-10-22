{ lib, ... }: {
  services = {
    # Display managers
    displayManager = {
      # CAUTION: ENABLE ONLY ONE DISPLAY MANAGER AT A TIME
      sddm = {
        enable = false;
        wayland.enable = true;
        autoNumlock = true;
      };
      gdm = {
        enable = true;
      };

      # Enable automatic login for the user.
      autoLogin = {
        enable = true;
        user = "astroreen";
      };

      # Defaul session to log in to. Perfect with auto login :)
      defaultSession = "hyprland";
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
  };
}
