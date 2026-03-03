{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    package = pkgs.steam; # Use the default Steam package
    remotePlay.openFirewall = true;
    protontricks.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    gamescopeSession = {
      enable = true;
      args = [
        "-w 3400"
        "-h 1440"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    steam-run
    steamcmd
  ];

  # Micro-compositor for games.
  # It can force games to run at specific resolutions and on specific monitors.
  programs.gamescope.enable = true;

  # Enable Steam hardware compatibility layer
  hardware.steam-hardware.enable = true;
}
