{ pkgs, ... }:
{
  imports = [
    # Apps (gui)
    ../modules/gui/apps.nix # Standard apps to install
    ../modules/gui/vesktop.nix # VDesktop configuration
    ../modules/gui/vscode/vscode.nix # VSCode
    ../modules/gui/obs.nix # OBS Studio
    ../modules/gui/lutris.nix # Lutris game manager

    # Terminal apps (tui)
    ../modules/tui/wine.nix # Wine configuration
    ../modules/tui/kitty.nix # Terminal
    ../modules/tui/shell/zsh.nix # Zsh configuration
    ../modules/tui/shell/shell.nix # Shell settings
    ../modules/tui/git.nix # Git
    ../modules/tui/htop.nix # Htop on steroids
    ../modules/tui/bat.nix # Cat(1) copy with wings
    ../modules/tui/lsd.nix # Next gen ls command
    ../modules/tui/devenv.nix # DevEnv for project scripts
    ../modules/tui/ranger.nix # Terminal file manager
    
    # Languages
    ../modules/lang/java.nix
    ../modules/lang/javascript.nix
    ../modules/lang/csharp.nix
    ../modules/lang/flutter/flutter-home.nix
  ];
}
