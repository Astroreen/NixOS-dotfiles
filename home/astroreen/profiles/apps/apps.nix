# Configuration for apps that can be installed just with package
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Communication
    telegram-desktop # Telegram
    viber # Viber
    caprine # Facebook Messenger
    mattermost-desktop # Mattermost
    whatsapp-electron # WhatsApp

    # Media
    mpv # Media player
    celluloid # MPV's frontend

    # Graphics & Design
    # gimp                          # GNU Image Manipulation Program
    # inkscape                      # Vector graphics editor
    # furmark # GPU stress test
    freecad # 3D CAD modeler

    # Productivity
    libreoffice # Office suite
    obsidian # Note-taking app

    # Development
    # github-desktop                # GitHub desktop client
    # thonny # Python IDE
    orca-slicer # 3D printing slicer

    # Internet
    qbittorrent # Torrent client

    # Security
    anydesk # Remote desktop application
  ];
}
