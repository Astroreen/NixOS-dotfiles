{ pkgs, ... }:
{
  # Nautilus context-menu extensions. Both are nautilus-python extensions, so
  # they add a shared CPython bootstrap + per-extension import cost to every
  # cold nautilus launch. Re-enable/disable together and re-measure.
  programs.nautilus-open-any-terminal = {
    enable = true;

    # Supported terminal emulators are listed in
    # https://github.com/Stunkymonkey/nautilus-open-any-terminal#supported-terminal-emulators.
    terminal = "kitty"; # "Open in kitty" context entry
  };

  services.gnome.sushi.enable = true; # File previewer for Nautilus

  environment.systemPackages = with pkgs; [
    nautilus # File manager
    sushi # File previewer
    code-nautilus # "Open in Code" context entry

    gsettings-desktop-schemas # Ensure gsettings schemas are available
  ];
}
