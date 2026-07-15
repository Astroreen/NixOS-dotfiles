_: {
  # Set your time zone.
  time.timeZone = "Europe/Vilnius";
  
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [
    "ru_RU.UTF-8/UTF-8"
    "lt_LT.UTF-8/UTF-8"
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru,lt";
    variant = ",phonetic,";
    options = "grp:alt_shift_toggle";
  };
}
