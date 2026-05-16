{ pkgs, ... }: {
  # Enable zsh so it could be added to SHELL variable int /etc/shell
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    # File utilities
    lsof # List open files and sockets
    unzip # Extract ZIP archives
    zip # Create ZIP archives
    p7zip # 7z archiver
    file # Determine file type

    # System diagnostics
    lshw # Hardware info
    smartmontools # smartctl — disk health
    iotop # I/O monitoring per process

    # Network tools
    wget # HTTP downloader
    nmap # Network scanner
    mtr # Traceroute + ping combined
    tcpdump # Packet capture
    socat # Network relay / swiss-army knife

    # Data processing
    jq # JSON processor
    yq-go # YAML processor

    # Dev/misc
    ncdu # Disk usage TUI
    bc # CLI calculator
    tmux # Terminal multiplexer
    entr # Re-run commands on file change
  ];
}
