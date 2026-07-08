# Configuration for apps that can be installed just with package
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Communication
    telegram-desktop # Telegram
    viber # Viber
    caprine # Facebook Messenger
    mattermost-desktop # Mattermost

    # Media
    mpv # Media player
    celluloid # MPV's frontend
    kdePackages.kdenlive


    # Graphics & Design
    # gimp                          # GNU Image Manipulation Program
    # inkscape                      # Vector graphics editor
    qview # Image viewer
    furmark # GPU stress test
    freecad # 3D CAD modeler

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
    qbittorrent # Torrent client

    # Security
    bitwarden-desktop # Password manager
    anydesk # Remote desktop application
  ];
}
