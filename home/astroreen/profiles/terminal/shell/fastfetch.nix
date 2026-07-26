_: {
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = ./assets/octane_avatar.jpg;
        width = 16;
        height = 7;
        padding = {
          right = 2;
        };
      };
      display = {
        size = {
          binaryPrefix = "si";
        };
        color = "blue";
        separator = ": ";
      };
      modules = [
        {
          type = "datetime";
          key = "Date & Time";
          format = "{1}-{3}-{11} {14}:{17}:{20}";
        }

        "break"

        {
          type = "cpuusage";
          key = "CPU";
          format = "{1}";
        }
        {
          type = "memory";
          key = "Memory";
          format = "{3} ({1} / {2})";
        }
        "uptime"

        "break"

        {
          type = "media";
          key = "Media";
          format = "{1}";
        }
      ];
    };
  };
}
