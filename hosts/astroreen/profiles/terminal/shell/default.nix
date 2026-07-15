{ pkgs, ... }: {

  # Default choices for the system
  imports = [
    ./kitty.nix
    ./zsh.nix
  ];

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

    # Data processing
    yq-go # YAML processor

    # Dev/misc
    ncdu # Disk usage TUI
  ];
}
