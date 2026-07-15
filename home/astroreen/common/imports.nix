_: {
  imports = [
    # Apps (gui)
    ../profiles/apps/apps.nix # Standard apps to install
    ../profiles/apps/clipboard.nix # Clipboard ui
    ../profiles/apps/vesktop.nix # VDesktop configuration
    ../profiles/apps/vscode # VSCode
    ../profiles/apps/obs.nix # OBS Studio
    ../profiles/apps/lutris.nix # Lutris game manager
    ../profiles/apps/nautilus.nix # Nautilus file manager configuration
    ../profiles/apps/kdeconnect.nix # KDE Connect configuration
    ../profiles/apps/vnc.nix # VNC server and client configuration
    ../profiles/apps/tailscale.nix # Tailscale tray and client configuration
    ../profiles/apps/browser.nix # Browser configuration
    ../profiles/apps/music.nix # Music apps configuration
    ../profiles/apps/minecraft.nix # Minecraft configuration

    # Terminal apps (tui)
    ../profiles/terminal/wine.nix # Wine configuration
    ../profiles/terminal/shell # Shell settings
    ../profiles/terminal/htop.nix # Htop on steroids
    ../profiles/terminal/devenv.nix # DevEnv for project scripts
    ../profiles/terminal/ranger.nix # Terminal file manager
    ../profiles/terminal/ai/fabric # Fabric AI CLI tool
    ../profiles/terminal/ai/opencode # Open Code
    ../profiles/terminal/ai/claude # Claude Code

    # Languages
    ../profiles/lang/java.nix
    ../profiles/lang/javascript.nix
    ../profiles/lang/csharp.nix
    ../profiles/lang/python.nix
    ../profiles/lang/flutter.nix
  ];
}
