{ pkgs, ... }: {
  # Linking the virtual microphones
  systemd.user.services.obs-pipewire-links = {
    description = "OBS PipeWire audio links";
    after = [
      "pipewire.service"
      "wireplumber.service"
    ];
    wants = [
      "pipewire.service"
      "wireplumber.service"
    ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "/bin/sh -c 'sleep 3'"; # ждём пока pipewire поднимется
      ExecStart = pkgs.writeShellScript "obs-links" ''
        ${pkgs.pipewire}/bin/pw-link "OBS Monitor Sink:monitor_FL" "OBS Virtual Mic:input_FL"
        ${pkgs.pipewire}/bin/pw-link "OBS Monitor Sink:monitor_FR" "OBS Virtual Mic:input_FR"
      '';
    };
  };

  # Create a virtual microhpone for OBS Studio to capture desktop audio without using the monitor of a physical sound card.
  services.pipewire = {
    extraConfig.pipewire."99-virtual-mic" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "obs_monitor_sink";
            "node.description" = "OBS Monitor Sink";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "obs_virtual_mic";
            "node.description" = "OBS Virtual Mic";
            "media.class" = "Audio/Source/Virtual";
            "audio.position" = "FL,FR";
          };
        }
      ];
    };

    wireplumber.extraConfig."99-obs-link" = {
      "wireplumber.links" = [
        {
          "link.output.node" = "obs_monitor_sink";
          "link.output.port" = "monitor_FL";
          "link.input.node" = "obs_virtual_mic";
          "link.input.port" = "input_FL";
        }
        {
          "link.output.node" = "obs_monitor_sink";
          "link.output.port" = "monitor_FR";
          "link.input.node" = "obs_virtual_mic";
          "link.input.port" = "input_FR";
        }
      ];
    };
  };
}
