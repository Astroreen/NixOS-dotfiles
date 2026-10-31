_: {
  imports = [ ../../../modules/power ];

  # Power profile per source (AC: balanced, battery: power saver), 60 Hz on
  # battery and the battery idle timeouts are dux settings, see the host's
  # assets/dux-settings.json. This covers what dux does not.
  custom.power.battery = {
    enable = true;
    # Same as dux's batteryLowThreshold (its low-battery warning)
    lowThreshold = 20;

    hyprland.disableOptions = [
      "animations:enabled"
      "decoration:blur:enabled"
      "decoration:shadow:enabled"
      "decoration:wobble:enabled" # dux layout setting
    ];

    units = {
      # A local dictation server keeps the dGPU awake; `auto` dictation goes
      # to hercules on battery and restarts it only when that is unreachable
      "whisper-server.service".restore = false;
      # Remote access stays available until the battery runs low
      "wayvnc.service".when = "low";
    };
  };
}
