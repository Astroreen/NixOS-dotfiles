# Configuration for apps that can be installed just with package
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # Games
    prismlauncher # Minecraft launcher

    # Communication
    discord # Discord
    telegram-desktop # Telegram
    viber # Viber
    caprine # Facebook Messenger
    mattermost-desktop # Mattermost

    # Media
    spotify # Music service
    mpv
    celluloid # Media player with frontend

    # Graphics & Design
    # gimp                          # GNU Image Manipulation Program
    # inkscape                      # Vector graphics editor
    qview # Image viewer

    # Productivity
    libreoffice # Office suite
    obsidian # Note-taking app

    # System utilities
    # gnome.gnome-system-monitor    # System monitor
    # gnome.gnome-disk-utility      # Disk utility

    # Development
    # github-desktop                # GitHub desktop client
    postman # API development environment
    warp-terminal # AI warp terminal
    jetbrains.idea-ultimate # IntelliJ IDEA Ultimate

    # File management
    localsend # Cross-platform file transfer

    # Internet
    #google-chrome
    vivaldi
    vivaldi-ffmpeg-codecs # Vivaldi Browser
    # thunderbird                   # Email client
    # qbittorrent                   # Torrent client

    # Security
    bitwarden-desktop # Password manager
  ];
}
