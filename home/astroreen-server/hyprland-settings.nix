{
  workspace = [
    "1, monitor:DP-3" # Main
    "2, monitor:DP-3" # Browser
    "3, monitor:DP-2" # Discord
    "4, monitor:HDMI-A-1" # Spotify
    "5, monitor:DP-3" # Obsidian

    # Any other workspace will be created in the focused monitor
    # (where is the mouse, there will be created a new workspace)
  ];

  monitor = [
    # [Monitor][Resolution@Hz][Virtual Place][Scale]
    "DP-3,3440x1440@165,0x0,1"
    "DP-2,1920x1080@60,3440x-480,1,transform,3"
    "HDMI-A-1,1920x1080@240,-1080x-480,1,transform,1"
    # "HDMI-A-1,1920x1080@60,-1920x-480,1"
  ];

  exec-once = [
    # Set primary monitor
    "sleep 5 && hyprctl keyword monitor HDMI-A-1,disable && sleep 5 && hyprctl keyword monitor DP-2,disable && sleep 5"
    "hyprctl keyword monitor HDMI-A-1,1920x1080@240,-1080x-480,1,transform,1 && hyprctl keyword monitor DP-2,1920x1080@60,3440x-480,1,transform,3"
    # Move mouse to main monitor
    "hyprctl dispatch workspace 1"
    # Start whisper server for voice transcription
    # ggml-tiny.bin ggml-base.bin ggml-large-v3-turbo-q5_0.bin
    "whisper-server -m /home/astroreen/apps/whisper.cpp/models/ggml-medium.bin --host 0.0.0.0 --port 7777 --language auto &"
  ];
}
