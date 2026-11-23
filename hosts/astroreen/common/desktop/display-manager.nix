{ pkgs, ... }:
let
  # https://github.com/Keyitdev/sddm-astronaut-theme
  # embeddedTheme picks one of its Themes/*.conf (astronaut, black_hole, cyberpunk, ...)
  sddm-astronaut = pkgs.sddm-astronaut.override { embeddedTheme = "astronaut"; };
in
{
  # The theme has to be in systemPackages too, so its fonts and QML are found
  environment.systemPackages = [ sddm-astronaut ];

  services = {
    # Display managers
    displayManager = {
      # CAUTION: ENABLE ONLY ONE DISPLAY MANAGER AT A TIME
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm; # Qt6 build, required by the astronaut theme
        wayland.enable = true;
        autoNumlock = true;
        theme = "sddm-astronaut-theme";
        extraPackages = [ sddm-astronaut ];
        # Only autologin once at boot; an explicit logout returns to SDDM.
        autoLogin.relogin = false;
      };
      gdm = {
        enable = false;
      };

      # Boot straight into Hyprland where hyprlock locks immediately so startup
      # apps load behind the lockscreen (like Windows ARSO).
      autoLogin = {
        enable = true;
        user = "astroreen";
      };

      # Default session preselected in the display manager.
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
