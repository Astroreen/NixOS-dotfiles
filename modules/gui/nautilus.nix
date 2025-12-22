{ pkgs, ... }:
{
  programs.nautilus-open-any-terminal = {
    enable = true;

    # Supported terminal emulators are listed in
    # https://github.com/Stunkymonkey/nautilus-open-any-terminal#supported-terminal-emulators.
    terminal = "kitty"; # Specify your preferred terminal emulator
  };

  services.gnome.sushi.enable = true; # File previewer for Nautilus

  environment.systemPackages = with pkgs; [
    nautilus # File manager
    nautilus-open-any-terminal # Open terminal in current directory
    sushi # File previewer
    code-nautilus # Open files in VSCode from Nautilus

    gsettings-desktop-schemas # Ensure gsettings schemas are available
  ];
}
