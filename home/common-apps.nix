_:
{
  imports = [
    # Apps (gui)
    ./modules/gui/apps.nix # Standard apps to install
    ./modules/gui/vesktop.nix # VDesktop configuration
    ./modules/gui/vscode # VSCode
    ./modules/gui/obs.nix # OBS Studio
    ./modules/gui/lutris.nix # Lutris game manager
    ./modules/gui/nautilus.nix # Nautilus file manager configuration

    # Terminal apps (tui)
    ./modules/tui/wine.nix # Wine configuration
    ./modules/tui/kitty.nix # Terminal
    ./modules/tui/shell # Shell settings
    ./modules/tui/htop.nix # Htop on steroids
    ./modules/tui/devenv.nix # DevEnv for project scripts
    ./modules/tui/ranger.nix # Terminal file manager
    ./modules/tui/ai/fabric # Fabric AI CLI tool
    ./modules/tui/ai/claude # Claude Code
    
    # Languages
    ./modules/lang/java.nix
    ./modules/lang/javascript.nix
    ./modules/lang/csharp.nix
    ./modules/lang/flutter
  ];
}
