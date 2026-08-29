{ pkgs, ... }:
{
  # Disabled (not removed): nautilus-python-based extensions add a shared
  # CPython bootstrap + per-extension import cost to every nautilus launch
  # (measured ~1.1s+ via strace). Re-enable by uncommenting if needed.
  # programs.nautilus-open-any-terminal = {
  #   enable = true;
  #
  #   # Supported terminal emulators are listed in
  #   # https://github.com/Stunkymonkey/nautilus-open-any-terminal#supported-terminal-emulators.
  #   terminal = "kitty"; # Specify your preferred terminal emulator
  # };

  services.gnome.sushi.enable = true; # File previewer for Nautilus

  environment.systemPackages = with pkgs; [
    nautilus # File manager
    # nautilus-open-any-terminal # Open terminal in current directory (disabled, see above)
    sushi # File previewer
    # code-nautilus # Open files in VSCode from Nautilus (disabled, see above)

    gsettings-desktop-schemas # Ensure gsettings schemas are available
  ];
}
