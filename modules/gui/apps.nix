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
    telegram-desktop # Telegram
    viber # Viber
    caprine # Facebook Messenger
    mattermost-desktop # Mattermost

    # Media
    spotify # Music service
    mpv # Media player
    celluloid # MPV's frontend

    # Graphics & Design
    # gimp                          # GNU Image Manipulation Program
    # inkscape                      # Vector graphics editor
    qview # Image viewer

    # Productivity
    libreoffice # Office suite
    obsidian # Note-taking app

    # Development
    # github-desktop                # GitHub desktop client
    postman # API development environment
    thonny # Python IDE

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
