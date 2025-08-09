{
    workspace = [
        "1, monitor:DP-3"       # Main
        "2, monitor:DP-3"       # Browser
        "3, monitor:DP-2"       # Discord
        "4, monitor:HDMI-A-1"   # Spotify

        # Any other workspace will be created in the focused monitor
        # (where is the mouse, there will be created a new workspace)
    ];
    
    monitor = [
        # [Monitor][Resolution@Hz][Virtual Place][Scale]
        "DP-3,3440x1440@165,0x0,1"
        "HDMI-A-1,1920x1080@240,-1080x0,1,transform,1"
        "DP-2,1920x1080@60,3440x0,1,transform,3"
    ];
}