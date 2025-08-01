# Configuration for apps that can be installed just with package
{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    prismlauncher

    # Communication
    # slack                       # Slack desktop client
    # signal-desktop
    # whatsapp-for-mac            # WhatsApp desktop client
    discord                       # Discord

    # Media
    pavucontrol
    spotify                       # Music service
    mpv celluloid                 # Video player with frontend
    # vlc                         # VLC media player

    # Graphics & Design
    # gimp                        # GNU Image Manipulation Program
    # inkscape                    # Vector graphics editor

    # Productivity
    libreoffice                   # Office suite
    obsidian                      # Note-taking app

    # System utilities
    # gnome.gnome-system-monitor  # System monitor
    # gnome.gnome-disk-utility    # Disk utility

    # Development
    # github-desktop              # GitHub desktop client
    postman                       # API development environment
    warp-terminal                 # AI warp termianl
    code-cursor-fhs               # VSCode fork with AI

    # File management
    # gnome.nautilus              # File manager
    # thunar                      # Lightweight file manager
    localsend                     # Cross-platform file transfer

    # Internet
    #google-chrome
    vivaldi vivaldi-ffmpeg-codecs # Vivaldi Browser
    # thunderbird                 # Email client
    # qbittorrent                 # Torrent client

    # Security
    bitwarden-desktop             # Password manager
  ];
}
